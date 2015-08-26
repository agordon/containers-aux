#!/bin/sh

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


# Compile a static binary of 'file'
# NOTES:
# 1. --prefix => to avoid accidental installation on the host system
# 2. --enable-static => to build a static libmagic.a
# 3. --datarootdir => hard-code the path in the 'file' binary,
#        will become '/share/misc/magic.mgc' INSIDE the container.
# 4. LDFLAGS  => forces libtool to build binary executable.
#                LDFLAGS="-static" is NOT sufficient - libtool will discard it.
#                passing it in ./configure will NOT work.
# 5. The compiled static binary will be ./file/src/file
# 6. The compiled magic database will be ./file/magic/magic.msc
(
    git clone https://github.com/file/file \
        && cd file \
        && autoreconf -if \
        && ./configure --prefix /tmp/foomagic --enable-static --datarootdir /share \
        && make LDFLAGS="-all-static"
) \
    || die "failed to build 'file' from source"

# Verify build
SRC=file/src/file
check_static_binary "$SRC"
cp "$SRC" "$DST/bin" \
    || die "failed to copy '$SRC' to '$DST/bin'"

# "install" the file binary and database
SRC=file/magic/magic.mgc
test -e "$SRC" || die "build failed: can't find '$SRC'"
cp "$SRC" "$DST/share/misc" \
    || die "failed to copy '$SRC' to '$DST/share/misc'"
