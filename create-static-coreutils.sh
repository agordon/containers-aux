#!/bin/sh

# containers-aux  -  supporting progams for 'containers'
# Copyright (C) 2015 Assaf Gordon (assafgordon@gmail.com)
# License: MIT
# https://github.com/agordon/container-aux

die()
{
    B=$(basename "$0")
    echo "$B: error: $@" >&2
    exit 1
}

check_static_binary()
{
    F="$1"
    test -z "$F" && die "missing file name param (in check_static_binary)"

    test -e "$F" || die "build failed: can't find '$SRC'"
    file -i "$F" | grep -Eq 'application/x-executable' \
        || die "build failed: '$F' is not a binary executable"
    ldd "$F" 1>/dev/null 2>/dev/null \
        && die "build failed: '$F' is not a static binary executable"
}

# Directory used as the root of the container
DST="$1"
test -z "$DST" \
    && die "missing target container directory."
# Create the busybox container root directory
mkdir -p "$DST/bin" \
    || die "failed to create container directory '$DST/bin'"

# Create a static 'single-binary' executable for GNU Coreutils
URL=http://ftpmirror.gnu.org/coreutils/coreutils-8.24.tar.xz
TAR=$(basename "$URL")
DIR=$(basename "$TAR" .tar.xz)
(
    mkdir coreutils && cd coreutils \
        && wget -O "$TAR" "$URL" \
        && tar -xf "$TAR" && cd "$DIR" \
        && ./configure --enable-single-binary LDFLAGS="-static" \
                --without-selinux --without-gmp \
        && make
) \
    || die "failed to build GNU coreutils"

# Verify build
SRC=coreutils/$DIR/src/coreutils
check_static_binary "$SRC"

cp "$SRC" "$DST/bin" \
    || die "failed to install '$SRC' in '$DST/bin'"

# Create links to the coreutils binary.
# the list of compiled programs is available with
#   coreutils --help
for i in \
    [ base64 basename cat chcon chgrp chmod chown chroot \
    cksum comm cp csplit cut date dd df dir dircolors dirname \
    du echo env expand expr factor false fmt fold ginstall groups \
    head hostid id join kill link ln logname ls md5sum mkdir mkfifo \
    mknod mktemp mv nice nl nohup nproc numfmt od paste pathchk pinky \
    pr printenv printf ptx pwd readlink realpath rm rmdir runcon seq \
    sha1sum sha224sum sha256sum sha384sum sha512sum shred shuf sleep \
    sort split stat stty sum sync tac tail tee test timeout touch tr \
    true truncate tsort tty uname unexpand uniq unlink uptime users \
    vdir wc who whoami yes ;
do
    ln -f "$SRC" "$DST/bin/$i" \
        || die "failed to create link from '$SRC' to '$DST/bin/$i'"
done
