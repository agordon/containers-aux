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


### create-host-container

**EXPERIMENTAL - USE AT YOUR OWN RISK**

The `create-host-container.sh` script uses bind-mounts to create a replica of
the host's directory structure. This is an alternative to the `tar + pseudo`
example shown in the _containers_'s README file.

Typical usage:

    $ sudo ./create-host-container.sh foo

    (add this if 'contain' will fails to mount tmpfs)
    $ sudo chown $USER foo

    $ contain foo
    (( inside the container, all host binaries from /bin , /usr/bin are available ))

To umount:

    $ sudo ./unmount-host-container.sh

**NOTE:**

This is HIGHLY experimental. As you are meddling with sudo and the host's system directories,
terrible things might happen. tread lightly.




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
