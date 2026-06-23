# Opsero Electronic Design Inc. 2025
#
# Thin wrapper around ../build.py, which does the real work (cross-platform
# build runner; see ../build.sh --help). The make interface below is kept for
# compatibility and will be REMOVED at the next version update -- please
# switch to ../build.sh.

TARGET ?= none
JOBS ?= 8
BUILD = ../build.sh

.DEFAULT_GOAL := xsa

.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make xsa TARGET=<val> JOBS=<n>'
	@echo '    Create the Vivado project and block design, then synthesize,'
	@echo '    implement and export to XSA.'
	@echo ''
	@echo '  make project TARGET=<val>'
	@echo '    Create the Vivado project and block design.'
	@echo ''
	@echo '  make clean TARGET=<val>'
	@echo '    Delete the project for the target.'
	@echo ''
	@echo '  make xsa_all / project_all / clean_all'
	@echo '    Same as above but for all targets.'
	@echo ''
	@echo 'DEPRECATED: this Makefile now wraps ../build.sh and will be removed'
	@echo 'at the next version update. Equivalent: ../build.sh xsa --target <val>'
	@echo ''
	@echo 'Valid targets:'
	@$(BUILD) labels | sed 's/^/    - /'

.PHONY: xsa
xsa:
	$(BUILD) xsa --target $(TARGET) --jobs $(JOBS)

.PHONY: project
project:
	$(BUILD) project --target $(TARGET)

.PHONY: ip
ip:
	$(BUILD) ip --target $(TARGET)

.PHONY: all
all: xsa_all

.PHONY: xsa_all
xsa_all:
	$(BUILD) xsa --target all --jobs $(JOBS)

.PHONY: project_all
project_all:
	$(BUILD) project --target all

.PHONY: clean
clean:
	$(BUILD) clean --target $(TARGET) --stage xsa

.PHONY: clean_all
clean_all:
	$(BUILD) clean --target all --stage xsa
	rm -rf .Xil vivado*.log vivado*.jou logs
