#!/bin/sh

die()
{
    BASE=$(basename "$0")
    echo "$BASE: error: $@" >&2
    exit 1
}

DST="$1"
test -z "$DST" && die "missing directory name to unmount"
test -d "$DST" || die "directory '$DST' not found"

# Directories from the host, to bind inside the container
# NOTE:
#  keep this list in sync with 'create-host-container.sh'
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

# UNMOUNT the directories
for i in $DIRLIST
do
    test -d "$DST/$i" || continue

    # FIXME:
    #   'mountpoint' is useless with bind-mounts:
    #   it does not detect bind-mounted directories correctly
    #   (as it assumes the file-system ID of the parent directory
    #    must be different from the mounted directory - which is not the case
    #    here).
    #   so always umount, and ignore the errors.

    # if mountpoint -q "$DST/$i" ; then
        umount "$DST/$i" \
    #      || die "failed to unmount-bind '$DST/$i'"
    # fi

done
