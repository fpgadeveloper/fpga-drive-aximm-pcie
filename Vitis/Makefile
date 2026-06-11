# Opsero Electronic Design Inc. 2025
#
# Thin wrapper around ../build.py, which does the real work (cross-platform
# build runner; see ../build.sh --help). The make interface below is kept for
# compatibility and will be REMOVED at the next version update -- please
# switch to ../build.sh.

TARGET ?= none
JOBS ?= 8
BUILD = ../build.sh

.DEFAULT_GOAL := workspace

.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make workspace TARGET=<target> JOBS=<val>'
	@echo '    Create the Vitis workspace and build the application.'
	@echo ''
	@echo '  make bootfile TARGET=<target>'
	@echo '    Generate a boot image for the target (bit or BOOT.BIN).'
	@echo ''
	@echo '  make all JOBS=<val>'
	@echo '    Workspace + boot files for all targets.'
	@echo ''
	@echo '  make clean TARGET=<target> / make clean_all'
	@echo '    Delete the workspace and boot files.'
	@echo ''
	@echo 'DEPRECATED: this Makefile now wraps ../build.sh and will be removed'
	@echo 'at the next version update. Equivalent: ../build.sh --target <val> --to bootfile'
	@echo ''
	@echo 'Valid targets:'
	@$(BUILD) --labels | sed 's/^/    - /'

.PHONY: workspace
workspace:
	$(BUILD) --target $(TARGET) --to workspace --jobs $(JOBS)

.PHONY: bootfile
bootfile:
	$(BUILD) --target $(TARGET) --to bootfile --jobs $(JOBS)

.PHONY: all
all:
	@for targ in $$($(BUILD) --labels); do \
		$(BUILD) --target $$targ --to bootfile --jobs $(JOBS) || exit $$?; \
	done

.PHONY: clean
clean:
	$(BUILD) --target $(TARGET) --clean --to bootfile

.PHONY: clean_all
clean_all:
	@for targ in $$($(BUILD) --labels); do \
		$(BUILD) --target $$targ --clean --to bootfile; \
	done
	rm -rf boot .Xil RemoteSystemsTempFiles
