# Opsero Electronic Design Inc. 2026
#
# Thin wrapper around build.py, which now sequences the Yocto / EDF flow
# directly (the engine is the four scripts in scripts/ — init-workspace,
# configure-build, build-image, package-output). This make interface is kept
# for compatibility and will be REMOVED at the next version update -- please
# switch to ../build.sh.

TARGET ?= none
JOBS ?= 8
BUILD = ./build.sh

.PHONY: help yocto all clean clean_all status status_all
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make yocto TARGET=<val> JOBS=<val>'
	@echo '    Build the Yocto Linux image (wraps: ../build.sh yocto --target <val>).'
	@echo ''
	@echo '  make all JOBS=<val>'
	@echo '    Same but for all targets.'
	@echo ''
	@echo '  make clean TARGET=<val>  |  make clean_all'
	@echo '    Delete the per-target Yocto workspace(s).'
	@echo ''
	@echo '  make status TARGET=<val>  |  make status_all'
	@echo '    Show per-stage artifact state.'
	@echo ''
	@echo "  Valid targets: run '../build.sh labels'"
	@echo ''
	@echo 'DEPRECATED: drive builds with ../build.sh instead.'

yocto:
	cd .. && $(BUILD) yocto --target $(TARGET) --jobs $(JOBS)

all:
	cd .. && $(BUILD) yocto --target all --jobs $(JOBS)

clean:
	cd .. && $(BUILD) clean --stage yocto --target $(TARGET)

clean_all:
	cd .. && $(BUILD) clean --stage yocto --target all

status:
	cd .. && $(BUILD) status --target $(TARGET)

status_all:
	cd .. && $(BUILD) status --target all
