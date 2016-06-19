#!/bin/sh

set -e

# containers-aux  -  supporting progams for 'containers'
# Copyright (C) 2015 Assaf Gordon (assafgordon@gmail.com)
# License: MIT
# https://github.com/agordon/containers-aux

# This script creates a template root filesystem for a new container
# (using the 'contain' program by Chris Webb).
# The '/bin' directory is populated with select executables, copied from
# the host's '/bin/' and '/usr/bin'.
# It can later be complemented with additional binaries.
# All the 'lib' directories (e.g. '/usr/lib') are created empty,
# with the expectation that those will be bind-mounted using the
# 'contain-user-host' script.
# Additionally, 'etc' directory is created with few useful files
# (such as passwd, group, rcS, etc.)
#
# It is meant to be used with 'setup-user-mapping.sh' and
# 'contain-user-host' scripts.
#


die()
{
    BASE=$(basename "$0")
    echo "$BASE: error: $@" >&2
    exit 1
}

DEST="$1"
test -z "$DEST" && die "missing destination directory"
test -d "$DEST" && die "directory '$DEST' already exists. aborting."


mkdir "$DEST"

# Directories to create
DIRLIST="
/bin

/etc
/etc/init.d

/root
/home
/home/user

/tmp

/proc
/sys
/dev

/lib
/lib32
/lib64

/usr
/usr/bin
/usr/lib
/usr/lib32
/usr/lib64
/usr/libexec
/usr/share

/usr/local/
/usr/local/lib
/usr/local/lib32
/usr/local/lib64
/usr/local/libexec
/usr/local/share

/var
/var/log
/var/run
/var/cache
/var/lib
"

# create directories in the destination root-fs
for i in $DIRLIST
do
    mkdir "$DEST/$i"
done


# Create /etc/passwd
cat<<EOF > "$DEST/etc/passwd"
root:x:0:0:root:/root:/bin/bash
user:x:1000:1000::/home/user:/bin/bash
nobody:x:65534:65534:::/bin/false
EOF

# Create /etc/group
cat<<EOF > "$DEST/etc/group"
root:x:0:
user:x:1000:
nobody:x:65534:
EOF

# Create DNS related files
printf "127.0.0.1\tlocalhost\n" > "$DEST/etc/hosts"
printf "hosts:  dns [!UNAVAIL=return] files" > "$DEST/etc/nsswitch.conf"
cat<<EOF > "$DEST/etc/resolv.conf"
#nameserver 8.8.4.4
#nameserver 4.2.2.2
EOF

# Create bash startup scripts
cat<<EOF > "$DEST/etc/profile"
[ "\$PS1" ] && [ "\$BASH" ] && [ "\$BASH" != "/bin/sh" ] \
    && [ -f /etc/bash.bashrc ] && . /etc/bash.bashrc
EOF
cat<<EOF > "$DEST/etc/bash.bashrc"
[ -z "$PS1" ] && return
shopt -s checkwinsize
PS1='\u@\h:\w\\\$ '
EOF

# Create startup/init script
newhostname=$(basename "$DEST" | tr -dc '_A-Za-z')
cat<<EOF > "$DEST/etc/init.d/rcS"
#!/bin/sh

echo Hello World From Container - starting root init script

# Setup Hostname
hostname "$newhostname"

# Enable localhost networking
ifconfig lo up

## Run something as non-root
# su -c /etc/init.d/rcS.user user

## Run something as gunicorn, exposing service as unix socket
#gunicorn \\
#    --daemon \\
#    --bind unix:/var/run/pastegin.sock \\
#    --user user --group user \\
#    --access-logfile /var/log/pastegin.access.log \\
#    --error-logfile /var/log/pastegin.error.log \\
#    --chdir /home/user pastegin:app

echo Initialization completed.
EOF
chmod a+x "$DEST/etc/init.d/rcS"

# Create startup/init script - executed as non-root user
cat<<EOF > "$DEST/etc/init.d/rcS.user"
#!/bin/sh

echo starting USER init script

#Simulate a never ending daemon....
while true ;
do
    echo Hello From fake daemon...
    date
    sleep 1
done

EOF
chmod a+x "$DEST/etc/init.d/rcS.user"



# Create bin directory, with select binaries
PROGS="ls rm cp mv mkdir head tail cat dash bash ps false true test sleep
date touch hostname uname
python perl socat"
for p in $PROGS ;
do
    src=$(which $p 2>/dev/null) || continue
    cp "$src" "$DEST/bin/"

    # make 'dash' the default shell
    test "$p" = "dash" && cp "$src" "$DEST/bin/sh"
done

# Few special-cases:
# for 'su' - use busybox (not the default 'su' which is tightly-coupled
# with PAM and somesuch)
busybox=$(which busybox 2>/dev/null) \
	|| die "can't find 'busybox' binary, please install busybox package."
cp "$busybox" "$DEST/bin/su"
# Use busyobox as ifconfig as well
ln "$DEST/bin/su" "$DEST/bin/ifconfig"
# Use busybox as env - and /usr/bin/env is the standard location
ln "$DEST/bin/su" "$DEST/usr/bin/env"

# Set permissions
chmod -R u=rwX,g=rX,o=rX "$DEST/"

# set some directories as world-writable permissions, and stickybit.
for d in /var/log /var/run /tmp ;
do
    chmod a+rwxt "$DEST/$d"
done
