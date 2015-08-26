PREFIX =
BINDIR = ${PREFIX}/bin
DESTDIR =

CC = gcc
CFLAGS = -g -std=gnu99 -Os -Wall -Wextra

BINARIES = list-containers

all: ${BINARIES}

list-containers: list-containers.o util.o

clean:
	rm -f -- ${BINARIES} ${SUIDROOT} tags *.o

install: ${BINARIES} ${SUIDROOT}
	mkdir -p ${DESTDIR}${BINDIR}
	install -s ${BINARIES} ${DESTDIR}${BINDIR}

tags:
	ctags -R

.PHONY: all clean install tags
