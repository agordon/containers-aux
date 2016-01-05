#!/bin/sh

# containers-aux  -  supporting progams for 'containers'
# Copyright (C) 2015 Assaf Gordon (assafgordon@gmail.com)
# License: MIT
# https://github.com/agordon/containers-aux

# This script performs one-time configuration of adding
# users on a Debian/Ubuntu system
# in a manner usable with contain's user-namespace mapping.

# The script creates two system users: lxc_root, lxc_users
# and their corresponding groups.
# It then updates /etc/sub{g,u}id and gives permissions
# to the current user to map user-namespaces into these users,
# in a manner that works with contain's -u/-g parameters.

die()
{
    BASE=$(basename "$0")
    echo "$BASE: error: $@" >&2
    exit 1
}

test "$(id -u)" = "0" || die "This script requires root privileges"

# Get the operator's username
test -z "$1" && die "missing operator's username (e.g. \$USER) - " \
                    "the user who will run the 'contain' program and be " \
                    "given the permissions to map to the newly created users".
operator="$1"
id -u -- "$1" 1>/dev/null 2>/dev/null \
    || die "'$1' is not a valid user on this system"

# Create new users
USERS="lxc_root lxc_user"

for u in $USERS ;
do
    adduser --system --disabled-login --no-create-home \
            --disabled-password --group --gecos "" \
            "$u" \
            || die "failed to create user '$u'"

    uid=$(id -u "$u") || die "failed to get UID of newly created user '$u'"
    gid=$(id -g "$u") || die "failed to get UID of newly created user '$u'"

    # Add the operator to new group (allowing the operator
    # to read the user's files if the group-permissions are given)
    adduser "$operator" "$u" \
        || die "failed to add user '$operator' to group '$u'"


    # Give the operator permissions to map user-namespaces
    printf "\n#added by containers-aux script on %s\n%s:%d:1\n\n" \
        "$(date -u)" "$operator" "$uid" >> /etc/subuid \
        || die "failed to add user mapping to /etc/subuid"

    printf "\n#added by containers-aux script on %s\n%s:%d:1\n\n" \
        "$(date -u)" "$operator" "$gid" >> /etc/subgid \
        || die "failed to add user mapping to /etc/subgid"
done
