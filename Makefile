# Opsero Electronic Design Inc. 2025
#
# Thin wrapper around build.py, which does the real work (cross-platform
# build runner; see ./build.sh --help). The make interface below is kept for
# compatibility and will be REMOVED at the next version update -- please
# switch to ./build.sh.
#
# Note: on Windows use ./build.sh directly from git bash; GNU make is not
# usable there (no sh-capable make is available).

TARGET ?= none
JOBS ?= 8
BUILD = ./build.sh

.DEFAULT_GOAL := bootimage

.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make bootimage TARGET=<val> JOBS=<val>'
	@echo '    Build and gather boot image files for given target.'
	@echo ''
	@echo '  make all JOBS=<val>'
	@echo '    Same but for all targets.'
	@echo ''
	@echo '  make clean TARGET=<val>'
	@echo '    Delete boot image files for given target.'
	@echo ''
	@echo '  make clean_all'
	@echo '    Delete boot image files for all targets.'
	@echo ''
	@echo 'DEPRECATED: this Makefile now wraps ./build.sh and will be removed'
	@echo 'at the next version update. Equivalent: ./build.sh all --target <val>'
	@echo ''
	@echo 'Valid targets:'
	@$(BUILD) labels | sed 's/^/    - /'

.PHONY: bootimage
bootimage:
	$(BUILD) all --target $(TARGET) --jobs $(JOBS)

.PHONY: all
all:
	$(BUILD) all --target all --jobs $(JOBS)

.PHONY: clean
clean:
	$(BUILD) clean --target $(TARGET) --stage package

.PHONY: clean_all
clean_all:
	rm -rf bootimages
