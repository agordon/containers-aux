#!/bin/sh

# containers-aux  -  supporting progams for 'containers'
# Copyright (C) 2015 Assaf Gordon (assafgordon@gmail.com)
# License: MIT
# https://github.com/agordon/containers-aux

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

# default 'sane' configuration - enable all applets
# Enable static build (to avoid adding so libraries inside the container)
# Build the executable
(
    git clone git://git.busybox.net/busybox \
        && cd busybox \
        && make defconfig \
        && sed -i '/CONFIG_STATIC/s/.*/CONFIG_STATIC=y/' .config \
        && make
) \
    || die "failed to build busybox"

# Verify build
SRC=busybox/busybox
check_static_binary "$SRC"


# create hard-links to all the applets.
# (NOTE: this uses hard-links)
"$SRC" --install "$DST/bin" \
    || die "failed to install Busybox applets from '$SRC' in '$DST/bin'"

## Done!
echo "BusyBox container root filesystem created."
echo "To start the container, run:"
echo "  ./contain '$DST'"
