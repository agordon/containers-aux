#!/bin/sh

die()
{
    BASE=$(basename "$0")
    echo "$BASE: error: $@" >&2
    exit 1
}

DST="$1"
test -z "$DST" && die "missing directory name to create (container's root)"
test -e "$DST" && die "'$DST' already exists - aborting."

mkdir "$DST" || die "failed to create '$DST'"

# Directories from the host, to bind inside the container
# NOTE:
#  keep this list in sync with 'unmount-host-container.sh'
DIRLIST="/bin
/sbin
/lib
/lib32
/lib64
/usr/bin
/usr/sbin
/usr/lib
/usr/lib32
/usr/lib64
/usr/libexec
/usr/bin
/usr/sbin
/usr/local/lib
/usr/local/lib32
/usr/local/lib64
/usr/local/libexec
"

# MOUNT the directories (if they exist on the host)
for i in $DIRLIST
do
    test -d "$i" || continue
    test -d "$DST/$i" \
        || mkdir -p "$DST/$i" \
        || die "failed to create '$DST/$i'"

    if ! mountpoint -q "$DST/$i" ; then
        mount --bind "$i" "$DST/$i" \
            || die "failed to mount-bind '$i' to '$DST/$i'"
    fi
done

echo "Host directories mounted on '$DST'".
echo "To start the container, run:"
echo "  contain $DST /bin/sh"
echo ""
echo "To unmount, run:"
echo "  ./umount-host-container.sh '$DST'"
echo ""

