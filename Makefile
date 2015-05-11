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
.NOTPARALLEL:

MAKEFILE=Makefile.generated
DIRECT_BUILD_PREFIX=build-

FINROC_ENVIRONMENT=$(FINROC_OPERATING_SYSTEM)_$(FINROC_ARCHITECTURE)
FINROC_ENVIRONMENT_NATIVE=$(FINROC_OPERATING_SYSTEM_NATIVE)_$(FINROC_ARCHITECTURE_NATIVE)
FINROC_CROSS_ROOT?=/undefined_system_root

all: makefile build

libdb: 
	@bash -c '[ -z "$$FINROC_HOME" ] && source scripts/setenv ; make_builder/scripts/updatelibdb $(FINROC_ENVIRONMENT_NATIVE)'
ifneq ($(FINROC_ENVIRONMENT),$(FINROC_ENVIRONMENT_NATIVE))
	@bash -c '[ -z "$$FINROC_HOME" ] && source scripts/setenv ; SYSTEM_ROOT=$$FINROC_CROSS_ROOT make_builder/scripts/updatelibdb $(FINROC_ENVIRONMENT)'
endif

make_builder/etc/libdb.$(FINROC_ENVIRONMENT_NATIVE): make_builder/etc/libdb.raw 
	@bash -c '[ -z "$$FINROC_HOME" ] && source scripts/setenv ; make_builder/scripts/updatelibdb $(FINROC_ENVIRONMENT_NATIVE)'

ifneq ($(FINROC_ENVIRONMENT),$(FINROC_ENVIRONMENT_NATIVE))
make_builder/etc/libdb.$(FINROC_ENVIRONMENT): make_builder/etc/libdb.raw
	@bash -c '[ -z "$$FINROC_HOME" ] && source scripts/setenv ; SYSTEM_ROOT=$$FINROC_CROSS_ROOT make_builder/scripts/updatelibdb $(FINROC_ENVIRONMENT)'
endif

makefile: make_builder/etc/libdb.$(FINROC_ENVIRONMENT_NATIVE) make_builder/etc/libdb.$(FINROC_ENVIRONMENT)
	$(MAKE) -C make_builder dist/build.jar
	@bash -c '[ -z "$$FINROC_HOME" ] && source scripts/setenv ; java -jar make_builder/dist/build.jar makebuilder.ext.finroc.FinrocBuilder --build=$$FINROC_TARGET $$FINROC_MAKE_BUILDER_FLAGS --makefile=$(MAKEFILE)'

build: $(MAKEFILE)
	@bash -c '[ -z "$$FINROC_HOME" ] && source scripts/setenv ; $(MAKE) --no-print-directory -f $(MAKEFILE) pre-build-hook'
	@bash -c '[ -z "$$FINROC_HOME" ] && source scripts/setenv ; $(MAKE) --no-print-directory -f $(MAKEFILE) $(WHAT)'
	@bash -c '[ -z "$$FINROC_HOME" ] && source scripts/setenv ; $(MAKE) --no-print-directory -f $(MAKEFILE) post-build-hook'

dependency_graph: make_builder/etc/libdb.$(FINROC_ENVIRONMENT_NATIVE) make_builder/etc/libdb.$(FINROC_ENVIRONMENT)
	$(MAKE) -C make_builder dist/build.jar
	@bash -c '[ -z "$$FINROC_HOME" ] && source scripts/setenv ; java -jar make_builder/dist/build.jar makebuilder.ext.finroc.FinrocBuilder --build=$$FINROC_TARGET $$FINROC_MAKE_BUILDER_FLAGS --dotfile'

$(MAKEFILE):
	$(MAKE) makefile

clean:
	$(MAKE) -f $(MAKEFILE) clean

%:
	@bash -c '[ "$(if $(findstring $(DIRECT_BUILD_PREFIX), $*),yes)" == "yes" ] || rm -f $(MAKEFILE)'
	@$(MAKE) --no-print-directory build WHAT=$(subst $(DIRECT_BUILD_PREFIX),,$*)

