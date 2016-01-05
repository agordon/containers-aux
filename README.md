Containers - Auxiliary Programs
===============================

This is a collection of supporting programs/scripts for
Chris Webb's [containers](https://github.com/arachsys/containers) project.

**Containers** are light-weight wrappers for the Linux-Containers interface
(think of it as more than `unshare(1)` and less than full-fledged `lxc` or
`docker`).


Installation
------------

First, install containers:

    git clone https://github.com/arachsys/containers.git
    cd containers
    make
    # optional
    sudo make install

Second, compile these programs:

    git clone https://github.com/agordon/containers-aux.git
    cd containers-aux
    make
    # optional
    sudo make install

NOTE:
The default containers installation installs `contain` as SUID executable.
Depending on your setup and needs, this might not be required.


Available programs/scripts
--------------------------

### list-containers

The containers package provides minimal functionality
without any management layer (that is on purpose, see
[this post](https://github.com/arachsys/containers/pull/2#issuecomment-134204055) ).

`list-containers` will search for running containers and print them to
STDOUT (saving just a bit of fiddling with PIDs).

Typical usage:

    $ contain /tmp/foo /bin/sh
    $ list-containers
    PID  init-pid(1)  init-cmd  root-dir
    458  10468        /bin/sh   /tmp/foo

PID (458) is the container, can be used with 'inject':

    $ CID=$(list-containers -fb) || exit
    $ inject "$CID" /bin/echo hello world

### create-container-rootfs.sh

The `create-container-rootfs.sh` creates a directory with template a
root-filesystem that can be used for a quick container setup. The
directory will contain:

1.  `/bin` - with some binaries copied from the host's `/bin/`,
    `/usr/bin`, etc. It will include `perl` and `python`.
	All binaries can be replaced or removed (or added).
	See also the static coreutils/busybox below.

2.  various `lib` directories (e.g. `/usr/lib`) - created empty,
    and will be bind-mounted with the container startup helper
	scripts (see below).

3.  `/etc/` - few files such as `passwd`,`bash.bashrc`,`init.d/rcS`
    are created to facilitate easier startup inside the container.

4.  `/var` and `/tmp` directories, with world-writable access
    and sticky-bits turned on.

To customize the container, edit `./etc/init.d/rcS` and add initialization
code.

### setup-user-mapping.sh

Creates two non-root users on the host: `lxc_root` and `lxc_user`,
and their corresponding groups. Adds mapping from the given user
(the operator, you) to these users in `/etc/sub{u,g}id` -
enabling `contain` to setup user namespace mapping.
This needs to be run only once, and will work for all later containers.
Mapping can be use explicitly with `contain`'s `-u`/`-g` options,
or automatically with the `contain-user-host` helper script.

Example:

    $ who am i
	gordon
    $ sudo ./setup-user-mapping.sh gordon

Will enable user `gordon` to later run `contain-user-host` with user mapping
of `lxc_root` and `lxc_user`.

### contain-* scripts

The scripts starts a container with user namespace mapping and
bind-mounting host's `lib` directories (based on a previously created
root-filesystem directory with `create-container-rootfs.sh`).

The scripts are:

1.  `contain-host` - performs host bind-mounting of `lib` directories.
2.  `contain-user-host` - same as above, adds automatic user namespace
    mapping of `root` to `lxc_root` and `user` to `lxc_user`. See
    `setup-user-mapping.sh` script.
3.  `contain-interactive` - same as above, takes one parameter (the
    root-filesystem directory) and automatically starts `/bin/bash` as
	a login shell with the contained root user.
4.  `contain-background-daemon` - same as #2, takes one parameter (the
    root-filesystem directory) and automatically starts
    `/etc/init.d/rcS` as a background process (runs the container with
    `nohup` and returns immediately)

Examples:

Create a container rootfs directory, start the container as the current
user (root in the container is the current user, no user-namespace mapping):

    $ ./create-container-rootfs.sh foobar
	$ ./contain-host ./foobar /bin/sh

Create a container rootfs directory, start the container with user namespace
mapping (root in the container is the `lxc_root` user on the host, non-root user
in the container is the `lxc_user` user on the host). `contain` must be installed
as suid binary (or use sudo) for this to work:

    $ ./create-container-rootfs.sh foobar
	$ ./contain-user-host ./foobar /bin/bash -l

The following are equivalent:

	$ ./contain-user-host ./foobar /bin/bash -l
    $ ./contain-interactive ./foobar

The following are equivalent way of running the container's init sequence
in the background:

	$ nohup ./contain-user-host -c ./foobar /bin/sh /etc/init.d/rcS &
    $ ./contain-background-daemon ./foobar


### create-static-busybox

The `create-static-busybox.sh` script downloads and builds the latest
[busybox](http://www.busybox.net/) binary, and creates a directory
structure suitible to be used as a container root directory.
The binary is statically-linked, and does not require any shared-libraries
(resulting in a very simple root directory structure).

Typical usage:

    $ ./create-static-busybox.sh foo

Then wait while busybox is being compiled. Once done,
a `foo` directory will be created, containing all the busybox
applets (e.g. `sh`,`awk`,`sort`,`ifconfig`, etc.) in the `bin` directory.
To use it as a container, run:

    $ contain ./foo
    (( inside the container , many common programs are availalbe in /bin ))

    # awk 2>&1 | head -n1
    BusyBox v1.24.0.git (2015-08-26 14:53:43 EDT) multi-call binary.

    # sort -h 2>&1 | head -n2
    sort: invalid option -- 'h'
    BusyBox v1.24.0.git (2015-08-26 14:53:43 EDT) multi-call binary.


### create-static-coreutils

Starting with GNU Coreutils version 8.24, coreutils can be built as a single
static binary (similar to busybox) - which greatly simplifies usage inside
containers. The `create-static-coreutils.sh` script downloads and builds
[GNU coreutils](http://www.gnu.org/software/coreutils), then
creates a a directory with hard-linked files to the `coreutils` single-binary.

Typical usage:

    $ ./create-static-coreutils.sh foo

Then wait while GNU coreutils is being compiled. Once done,
a `foo` directory will be created, containing the `coreutils`
binary and links to the various programs (e.g. `cp`,`rm`,`sort`,`head`, etc.)
in the `bin` directory. To use it as a container, run:

    $ contain ./foo /bin/sort --help

**NOTE:**

1.  `busybox` includes many of the same utilities (e.g. `sort`,`cp`) as
    GNU coreutils, but with limited funtionality. Depending on your needs,
    you might prefer to override the busybox utils with GNU coreutils.
2.  `busybox` includes a shell (`ash`, installed as `./busybox-container/bin/sh`) -
    so it can be easily used as a container root directory with interactive shell.
    GNU `coreutils` does *not* include a shell - a container directory
    created by `create-static-coreutils.sh` will not suffice to run
    an entire container shell.
3.  Common usage will be to first create the busybox container (with shell,
    and many other utilities), then install (and override) it with the
    GNU coreutils programs:

        $ ./create-static-busybox.sh foo
        $ ./create-static-coreutils.sh foo
        $ contain ./foo /bin/sh
        (( inside the container , awk is busybox, and sort is GNU coreutils ))

        # awk 2>&1 | head -n1
        BusyBox v1.24.0.git (2015-08-26 14:53:43 EDT) multi-call binary.

        # sort --version | head -n1
        sort (GNU coreutils) 8.24

### create-static-file-magic

The `create-static-file-magic.sh` script downloads and builds a static
version of the `file(1)` program (the magic file detection utility).

Typical usage:

    $ ./create-static-file-magic.sh foo

Then wait while libmagic/file are being compiled. Once done,
a `foo` directory will be created, containing the `./bin/file` binary
and `/share/misc/magic.mgc` database.
To use it as a container, run:

    $ contain ./foo /bin/file --help

**NOTE:**

`file` by itself is not sufficient for a self-contained container.
typically this would be combined with busybox/coreutils programs:


        $ ./create-static-busybox.sh foo
        $ ./create-static-file-magic.sh foo
        $ contain ./foo /bin/sh
        (( inside the container , 'file' is available ))

        # file --version
        file-5.24
        magic file from /share/misc/magic

        # file /bin/sh
        /bin/sh: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, for GNU/Linux 2.6.24, stripped

### create-static-7za

Same as above, creates a static `7za` binary executable (7z (de)compression program).

        $ ./create-static-7za.sh foo

Installs the static binary in `./foo/bin/7za`.

### contain-host

The `contain-host` script uses bind-mounts to create a replica of
the host's directory structure. This is an alternative to the `tar + pseudo`
example shown in the _containers_'s README file.

Typical usage:

    $ mkdir foo
    $ contain-host foo /bin/bash
    bash-4.3#

The 'bash-4.3' prompt is inside the container, and in it,
 `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`, `/usr/local/bin`,
 `/usr/local/sbin` (including the relevant `*/lib` directories)
are all mirrored from the host.

When the contained process terminates, the bind-mounts are automatically
unmounted.


Contact
-------

Assaf Gordon

Assafgordon@gmail.com

https://github.com/agordon

License: MIT

Additional files:

    Makefile, utils.c, contain.h:
      copied from <https://github.com/arachsys/containers>
      Copyright (C) 2013 Chris Webb <chris@arachsys.com>
      License: MIT
