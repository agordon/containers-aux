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
mkdir -p "$DST/share/misc" \
    || die "failed to create container directory '$DST/share/misc'"


# Compile a static binary of '7za'
URL=http://sourceforge.net/projects/p7zip/files/p7zip/9.38.1/p7zip_9.38.1_src_all.tar.bz2
TAR=$(basename "$URL")
# NOTE: annoyingly not the same as the tarball name...
DIR=p7zip_9.38.1
(
    mkdir p7zip && cd p7zip \
        && wget -O "$TAR" "$URL" \
        && tar -xf "$TAR" \
        && cd "$DIR" \
        && make 7za LDFLAGS="-static"
) \
    || die "failed to build '7za' from source"

# Verify build
SRC=p7zip/$DIR/bin/7za
check_static_binary "$SRC"
cp "$SRC" "$DST/bin" \
    || die "failed to copy '$SRC' to '$DST/bin'"
