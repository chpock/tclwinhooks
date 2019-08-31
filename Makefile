# wintclhooks
# Copyright (C) 2019 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

NAME = tclwinhooks

DLLNAME = $(NAME)$(DLLSUFFIX).dll

DEBUG ?= 0
AMD64 ?= 0

CC     = $(_ODB_)-w64-mingw32-gcc
RC     = $(_ODB_)-w64-mingw32-windres
AR     = $(_ODB_)-w64-mingw32-ar
RUNLIB = $(_ODB_)-w64-mingw32-ranlib
CPP    = $(CC)

ifeq ($(DEBUG),1)
_ODN_         = debug
#TCLDBGFIX     = g
else
_ODN_         = final
endif

ifeq ($(AMD64),1)
_ODB_         = x86_64
CFLAGS        += -m64 -D_AMD64_
TCLCONFPARAM  = --enable-64bit
LDFLAGS       += -m64
RCFLAGS       += -F pe-x86-64
DLLSUFFIX     = 64
else
_ODB_         = i686
CFLAGS        += -m32
TCLCONFPARAM  = --disable-64bit
LDFLAGS       += -m32
RCFLAGS       += -F pe-i386
DLLSUFFIX     =
endif

# use correct tools for mingw
CFLAGS += -B/usr/$(_ODB_)-w64-mingw32/bin

BLDDIR := $(shell pwd)

SRCDIR       = $(BLDDIR)/src
GENERICDIR   = $(BLDDIR)/generic
PKGDIR       = $(OUTDIR)/package
RELEASEDIR   = $(BLDDIR)/release

TCLVER       = 86
TCLVERX      = 8.6
TCLDIR       = $(BLDDIR)/deps/tcl
TCLSH        = $(TCLOUTDIR)/bin/tclsh$(TCLVER).exe
TCLCONFFLAGS = CC="$(CC)" AR="$(AR)" RC="$(RC)" RUNLIB="$(RUNLIB)" CFLAGS=-B/usr/$(_ODB_)-w64-mingw32/bin
TCLOUTDIR    = $(OUTDIR)/tcl
TCLLIBS      = $(TCLOUTDIR)/lib/libtclstub$(TCLVER)$(TCLDBGFIX).$(LIBEXT)

OUTDIR = $(BLDDIR)/out.$(_ODN_).$(_ODB_)

OBJDIR      = $(OUTDIR)/obj
INCLUDE     = $(TCLOUTDIR)/include
DLLFULLNAME = $(PKGDIR)/$(DLLNAME)
MAP = $(OUTDIR)/$(NAME).map
KIT = $(OUTDIR)/$(NAME).kit

OBJEXT          = o
LIBEXT          = a
SHLIB_LD_LIBS   = $(LIBS)
SHLIB_CFLAGS    =
SHLIB_SUFFIX    = .dll
#LIBS            = -lrpcrt4 -lcrypt32 -luxtheme -lcredui -lmpr -lsetupapi -lpsapi -lsecur32 -lpdh -liphlpapi \
#                  -lwintrust -lwtsapi32 -lnetapi32 -lkernel32 -luser32 -ladvapi32 -luserenv -lws2_32 -lgdi32 \
#                  -lwinmm -lpowrprof -lversion -lwinspool -lcomdlg32 -limm32 -lcomctl32 -lshell32 -luuid -lole32 -loleaut32 \
#                  -Wl,-Bstatic -lstdc++ -lpthread -Wl,-Bdynamic

# warning flags
CFLAGS          += -O2 -fomit-frame-pointer

CFLAGS          += -fno-exceptions -DUNICODE -D_UNICODE

ifeq ($(DEBUG),1)
CFLAGS        += -g
TCLCONFPARAM  += --enable-symbols
else
LDFLAGS       += -s -Wl,--exclude-all-symbols
TCLCONFPARAM  += --disable-symbols
endif

TCLCONFPARAM += --enable-threads --prefix=$(TCLOUTDIR)

LINK_OBJS = $(OBJDIR)/$(NAME).$(OBJEXT) \
            $(TCLLIBS) \
            $(OBJDIR)/$(NAME).res.$(OBJEXT)

VER_MAJOR = $(shell grep "define VER_MAJOR" version.h | grep -oE "[[:digit:]]+")
VER_MINOR = $(shell grep "define VER_MINOR" version.h | grep -oE "[[:digit:]]+")
VER_REVIS = $(shell grep "define VER_REVIS" version.h | grep -oE "[[:digit:]]+")
VER_BUILD = $(shell expr 1 + `grep "define VER_BUILD" version.h | grep -oE "[[:digit:]]+"`)
VER_FULL  = $(VER_MAJOR).$(VER_MINOR).$(VER_REVIS).$(VER_BUILD)
VER_SHORT = $(VER_MAJOR).$(VER_MINOR).$(VER_REVIS)

SOURCES = $(SRCDIR)/tclwinhooks.c \
          $(SRCDIR)/tclwinhooks.h \
          version.h

GENERIC = $(PKGDIR)/pkgIndex.tcl \
          $(PKGDIR)/tclwinhooks.tcl

VERSIONED_SOURCES = $(SRCDIR)/tclwinhooks.c \
                    $(SRCDIR)/tclwinhooks.h \
                    $(GENERICDIR)/tclwinhooks.tcl \
                    $(GENERICDIR)/pkgIndex.tcl.in


# $(TCLLIBDIR)/modules/uev $(TCLLIBDIR)/modules/log
#ADDONS = src/procarg \
#	 $(TWAPIDIR)/twapi/tcl $(TWAPIDIR)/pkgIndex.tcl $(TWAPIDIR)/twapi_entry.tcl \
#         addons/boot.tcl addons/rm/rm.tcl addons/rm/pkgIndex.tcl

.PHONY: all build clean test package

all: build

version.h: $(VERSIONED_SOURCES)
	sed -i 's/define VER_BUILD .*/define VER_BUILD $(VER_BUILD)/' version.h

$(OBJDIR)/$(NAME).$(OBJEXT): $(SOURCES) $(TCLOUTDIR)/include/tcl.h
	@echo
	@echo "#### Build ext obj..."
	CPATH=$(INCLUDE) $(CPP) $(CFLAGS) -DUSE_TCL_STUBS -DPACKAGE_NAME=\"$(NAME)\" -DPACKAGE_VERSION=\"$(VER_SHORT)\" -c -o $@ $<

$(OBJDIR)/$(NAME).res.$(OBJEXT): $(NAME).rc version.h
	@echo
	@echo "#### Build plugin resources..."
	$(RC) $(RCFLAGS) -o $@ --include "$(TKDIR)/win/rc" $<

$(DLLFULLNAME): $(PKGDIR) $(LINK_OBJS)
	@#${SHLIB_LD} $(CC) $(LDFLAGS) -o $@ -pipe -static-libgcc -municode -Wl,--kill-at $(LINK_OBJS) $(SHLIB_LD_LIBS)
	$(CC) -shared $(LDFLAGS) -o "$@" -pipe -static-libgcc -municode $(LINK_OBJS) $(SHLIB_LD_LIBS)
ifeq ($(DEBUG),1)
	objcopy --only-keep-debug "$@" "$(DLLFULLNAME).debug"
#	strip --strip-debug --strip-unneeded "$@"
	objcopy --add-gnu-debuglink="$(DLLFULLNAME).debug" "$@"
endif

$(PKGDIR)/pkgIndex.tcl: $(GENERICDIR)/pkgIndex.tcl.in
	cat "$<" | sed -e 's/@@VERSION@@/$(VER_SHORT)/' >"$@"

$(PKGDIR)/tclwinhooks.tcl: $(GENERICDIR)/tclwinhooks.tcl
	tools/nagelfar_sh.exe -exitcode "$(shell cygpath -w "$<")"
	cp -f "$<" "$@"

$(OBJDIR): $(OUTDIR)
	@mkdir -p "$@"

$(TCLOUTDIR): $(OUTDIR)
	@mkdir -p "$@"

$(PKGDIR): $(OUTDIR)
	@mkdir -p "$@"

$(OUTDIR):
	@mkdir -p "$@"

$(OUTDIR)/lib: $(OUTDIR)
	@mkdir -p "$@"

$(OUTDIR)/lib/tcl$(TCLVERX): $(OUTDIR)/lib
	mkdir -p "$@"
	cd "$(TCLDIR)/library" && cp -r * "$@"

$(TCLSH) $(TCLLIBS) $(TCLOUTDIR)/include/tcl.h: $(TCLOUTDIR)
	make -C $(TCLDIR)/win clean
	cd $(TCLDIR)/win && $(TCLCONFFLAGS) ./configure $(TCLCONFPARAM)
	make -C $(TCLDIR)/win all
	make -C $(TCLDIR)/win install

$(RELEASEDIR): $(VERSIONED_SOURCES) version.h
	make AMD64=0
	make AMD64=1
	mkdir -p $(RELEASEDIR)
	cp -f "$(BLDDIR)/out.$(_ODN_).i686"/package/* "$(RELEASEDIR)"
	cp -f "$(BLDDIR)/out.$(_ODN_).x86_64"/package/* "$(RELEASEDIR)"

build: $(OBJDIR) $(DLLFULLNAME) $(GENERIC)
	@echo Build DONE.

clean:
	rm -rf out.*/*
	make -C $(TCLDIR)/win clean || echo "Nothing to do"

release: $(RELEASEDIR)

test: release
	@echo
	@echo "#### Run tests..."
