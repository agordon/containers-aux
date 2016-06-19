PREFIX = /usr/local/
BINDIR = ${PREFIX}/bin

CC = gcc
CFLAGS = -g -std=gnu99 -Os -Wall -Wextra

BINARIES = list-containers
SCRIPTS = \
	contain-background-daemon \
	contain-host \
	contain-user-host \
	contain-interactive \
	contain-helper

all: ${BINARIES}

list-containers: list-containers.o util.o

clean:
	rm -f -- ${BINARIES} *.o

install: ${BINARIES} ${SUIDROOT}
	mkdir -p ${BINDIR}
	install -s ${BINARIES} ${BINDIR}
	install ${SCRIPTS} ${BINDIR}

.PHONY: all clean install
