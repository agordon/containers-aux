#!/bin/sh

die()
{
    BASE=$(basename "$0")
    echo "$BASE: error: $@" >&2
    exit 1
}

DEST="$1"
test -z "$DEST" && die "missing destination directory"

mkdir -p "$DEST" || die "failed to create directory '$DEST/etc'"
mkdir -p "$DEST/etc/init.d" \
    || die "failed to create directory '$DEST/etc/init.d'"

# Create /etc/passwd
cat<<\EOF > "$DEST/etc/passwd"
root:x:0:0:root:/root:/bin/bash
user:x:1000:1000::/home/user:/bin/bash
nobody:x:65534:65534:::/bin/false
EOF

# Create /etc/group
cat<<\EOF > "$DEST/etc/group"
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
cat<<\EOF > "$DEST/etc/profile"
[ "\$PS1" ] && [ "\$BASH" ] && [ "\$BASH" != "/bin/sh" ] \
    && [ -f /etc/bash.bashrc ] && . /etc/bash.bashrc
EOF
cat<<\EOF > "$DEST/etc/bash.bashrc"
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
hostname "foobar"

# Enable localhost networking
ifconfig lo up

## Run something as non-root
# su -c /etc/init.d/rcS.user user

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
