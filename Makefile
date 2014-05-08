# You received this file as part of Finroc
# A framework for intelligent robot control
#
# Copyright (C) Finroc GbR (finroc.org)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

.PHONY: all libdb makefile build clean
.NOPARALLEL:

MAKEFILE=Makefile.generated
DIRECT_BUILD_PREFIX=build-

all: makefile build

libdb:
	@bash -c '[ -z $$FINROC_HOME ] && source scripts/setenv ; updatelibdb'

makefile:
	$(MAKE) -C make_builder
	@bash -c '[ -z $$FINROC_HOME ] && source scripts/setenv ; java -jar make_builder/dist/build.jar makebuilder.ext.finroc.FinrocBuilder --build=$$FINROC_TARGET --report-unmanaged-files --makefile=$(MAKEFILE)'

build: $(MAKEFILE)
	$(MAKE) -f $(MAKEFILE) $(WHAT)

dependency_graph:
	$(MAKE) -C make_builder
	@bash -c '[ -z $$FINROC_HOME ] && source scripts/setenv ; java -jar make_builder/dist/build.jar makebuilder.ext.finroc.FinrocBuilder --build=$$FINROC_TARGET --report-unmanaged-files --dotfile'

$(MAKEFILE):
	$(MAKE) makefile

clean:
	$(MAKE) -f $(MAKEFILE) clean

%:
override KEEP_MAKEFILE = $(if $(findstring $(DIRECT_BUILD_PREFIX), $*),yes)
	@bash -c '[ "$(KEEP_MAKEFILE)" == "yes" ] || rm -f $(MAKEFILE)'
	$(MAKE) build WHAT=$(subst $(DIRECT_BUILD_PREFIX),,$*)
