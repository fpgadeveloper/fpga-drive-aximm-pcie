# Opsero Electronic Design Inc. 2025
#
# Thin wrapper around ../build.py, which does the real work (cross-platform
# build runner; see ../build.sh --help). The make interface below is kept for
# compatibility and will be REMOVED at the next version update -- please
# switch to ../build.sh.

TARGET ?= none
JOBS ?= 8
BUILD = ../build.sh

.DEFAULT_GOAL := bootfile

.PHONY: help
help:
	@echo 'Usage:'
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
	@echo 'at the next version update. Equivalent: ../build.sh standalone --target <val>'
	@echo ''
	@echo 'Valid targets:'
	@$(BUILD) labels | sed 's/^/    - /'

.PHONY: bootfile
bootfile:
	$(BUILD) standalone --target $(TARGET) --jobs $(JOBS)

.PHONY: all
all:
	$(BUILD) standalone --target all --jobs $(JOBS)

.PHONY: clean
clean:
	$(BUILD) clean --target $(TARGET) --stage standalone

.PHONY: clean_all
clean_all:
	$(BUILD) clean --target all --stage standalone
	rm -rf boot .Xil RemoteSystemsTempFiles
