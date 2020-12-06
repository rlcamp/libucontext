ARCH := $(shell uname -m)
ifeq ($(ARCH),$(filter $(ARCH),i386 i686))
	override ARCH = x86
endif

LIBDIR := /lib
CFLAGS := -ggdb3 -O2 -Wall
CPPFLAGS := -Iarch/${ARCH} -Iarch/common
EXPORT_UNPREFIXED := yes
FREESTANDING := no

ifeq ($(FREESTANDING),yes)
	CFLAGS += -DFREESTANDING -isystem arch/${ARCH}/freestanding
	EXPORT_UNPREFIXED = no
endif

ifeq ($(EXPORT_UNPREFIXED),yes)
	CFLAGS += -DEXPORT_UNPREFIXED
endif

LIBUCONTEXT_C_SRC = $(wildcard arch/${ARCH}/*.c)
LIBUCONTEXT_S_SRC = $(wildcard arch/${ARCH}/*.S)

LIBUCONTEXT_OBJ = ${LIBUCONTEXT_C_SRC:.c=.o} ${LIBUCONTEXT_S_SRC:.S=.o}
LIBUCONTEXT_SOVERSION = 0
LIBUCONTEXT_NAME = libucontext.so
LIBUCONTEXT_STATIC_NAME = libucontext.a
LIBUCONTEXT_SONAME = libucontext.so.${LIBUCONTEXT_SOVERSION}
LIBUCONTEXT_PATH = ${LIBDIR}/${LIBUCONTEXT_SONAME}
LIBUCONTEXT_STATIC_PATH = ${LIBDIR}/${LIBUCONTEXT_STATIC_NAME}

all: ${LIBUCONTEXT_SONAME} ${LIBUCONTEXT_STATIC_NAME}

${LIBUCONTEXT_STATIC_NAME}: ${LIBUCONTEXT_OBJ}
	$(AR) rcs ${LIBUCONTEXT_STATIC_NAME} ${LIBUCONTEXT_OBJ}

${LIBUCONTEXT_NAME}: ${LIBUCONTEXT_OBJ}
	$(CC) -o ${LIBUCONTEXT_NAME} -Wl,-soname,${LIBUCONTEXT_SONAME} \
		-shared ${LIBUCONTEXT_OBJ} ${LDFLAGS}

${LIBUCONTEXT_SONAME}: ${LIBUCONTEXT_NAME}
	ln -sf ${LIBUCONTEXT_NAME} ${LIBUCONTEXT_SONAME}

.c.o:
	$(CC) -std=c99 -D_BSD_SOURCE -fPIC -DPIC ${CFLAGS} ${CPPFLAGS} -c -o $@ $<

.S.o:
	$(CC) -fPIC -DPIC ${CFLAGS} ${CPPFLAGS} -c -o $@ $<

clean:
	rm -f ${LIBUCONTEXT_NAME} ${LIBUCONTEXT_SONAME} ${LIBUCONTEXT_STATIC_NAME} \
		${LIBUCONTEXT_OBJ} test_libucontext

install: all
	install -D -m755 ${LIBUCONTEXT_NAME} ${DESTDIR}${LIBUCONTEXT_PATH}
	install -D -m664 ${LIBUCONTEXT_STATIC_NAME} ${DESTDIR}${LIBUCONTEXT_STATIC_PATH}
	ln -sf ${LIBUCONTEXT_SONAME} ${DESTDIR}${LIBDIR}/${LIBUCONTEXT_NAME}

check: test_libucontext ${LIBUCONTEXT_SONAME}
	env LD_LIBRARY_PATH=$(shell pwd) ./test_libucontext

test_libucontext: test_libucontext.c ${LIBUCONTEXT_NAME}
	$(CC) -std=c99 -D_BSD_SOURCE ${CFLAGS} ${CPPFLAGS} $@.c -o $@ -L. -lucontext

.PHONY: check
