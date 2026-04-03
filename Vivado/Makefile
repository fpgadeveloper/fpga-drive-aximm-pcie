# Opsero Electronic Design Inc. 2025
#
# This Makefile can be used to build the Vivado projects.

CP = cp -rf
MKDIR = mkdir -p
RM = rm -rf
ROOT_DIR = $(shell pwd)
VIVADO = $(XILINX_VIVADO)/bin/vivado

# defaults
.DEFAULT_GOAL := xsa
TARGET ?= none
JOBS ?= 8

# valid targets
# UPDATER START
BD_NAME = fpgadrv
auboard_target := 0
kc705_hpc_target := 0
kc705_lpc_target := 0
kcu105_hpc_target := 0
kcu105_lpc_target := 0
pz_7015_target := 0
pz_7030_target := 0
uzev_target := 0
vc707_hpc1_target := 0
vc707_hpc2_target := 0
vc709_hpc_target := 0
vck190_fmcp1_target := 0
vck190_fmcp2_target := 0
vhk158_target := 0
vmk180_fmcp1_target := 0
vmk180_fmcp2_target := 0
vek280_target := 0
vpk120_target := 0
vpk180_target := 0
vcu118_target := 0
zc706_hpc_target := 0
zc706_lpc_target := 0
zcu104_target := 0
zcu106_hpc0_target := 0
zcu106_hpc1_target := 0
zcu111_target := 0
zcu208_target := 0
zcu216_target := 0
# UPDATER END

TARGET_LIST := $(sort $(patsubst %_target,%,$(filter %_target,$(.VARIABLES))))

# Vivado paths
VIV_SCRIPT_BD = scripts/build.tcl
VIV_SCRIPT_XSA = scripts/xsa.tcl
VIV_DIR = $(TARGET)

# output files
VIV_XPR = $(VIV_DIR)/$(TARGET).xpr
VIV_XSA = $(VIV_DIR)/$(BD_NAME)_wrapper.xsa
VIV_LOG_DIR = logs
VIV_XPR_LOG = $(VIV_LOG_DIR)/$(TARGET)_xpr.log
VIV_XPR_JOU = $(VIV_LOG_DIR)/$(TARGET)_xpr.jou
VIV_XSA_LOG = $(VIV_LOG_DIR)/$(TARGET)_xsa.log
VIV_XSA_JOU = $(VIV_LOG_DIR)/$(TARGET)_xsa.jou
VIV_BIT = $(VIV_DIR)/$(TARGET).runs/impl_1/$(BD_NAME)_wrapper.bit
VIV_LOCK = $(ROOT_DIR)/.$(TARGET).lock

.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make xsa TARGET=<val> JOBS=<n>'
	@echo '    Create the Vivado project and block design, then synthesize'
	@echo '    implement and export to XSA.'
	@echo ''
	@echo '  make project TARGET=<val>'
	@echo '    Create the Vivado project and block design.'
	@echo ''
	@echo '  make clean TARGET=<val>'
	@echo '    Clean runs for target project.'
	@echo ''
	@echo '  make xsa_all JOBS=<n>'
	@echo '    Same as make xsa but for all targets.'
	@echo ''
	@echo '  make project_all'
	@echo '    Same as make project but for all targets.'
	@echo ''
	@echo '  make clean_all'
	@echo '    Same as make clean but for all targets.'
	@echo ''
	@echo 'Parameters:'
	@echo ''
	@echo '  TARGET: Name of the target design, must be one of the following:'
	@$(foreach targ,$(TARGET_LIST),echo "    - $(targ)";)
	@echo ''
	@echo '  JOBS: Optional param to set number of synthesis jobs (default 8)'
	@echo ''
	@echo 'Example usage:'
	@echo '  make xsa TARGET=$(word 1,$(TARGET_LIST))'
	@echo ''

.PHONY: all
all: xsa_all

.PHONY: xsa
xsa:
	@if [ -f $(VIV_LOCK) ]; then \
		echo "$(TARGET) is locked. Skipping..."; \
	else \
		touch $(VIV_LOCK); \
		$(MAKE) xsa_locked TARGET=$(TARGET) JOBS=$(JOBS); \
		rm -f $(VIV_LOCK); \
	fi

xsa_locked: $(VIV_XSA) check_warnings
$(VIV_XSA): $(VIV_XPR)
	$(MKDIR) $(VIV_LOG_DIR)
	$(RM) $(VIV_XSA_LOG) $(VIV_XSA_JOU)
	$(VIVADO) -mode batch -notrace -source $(VIV_SCRIPT_XSA) -log $(VIV_XSA_LOG) -journal $(VIV_XSA_JOU) -tclargs $(TARGET) $(JOBS)

check_warnings:
	@grep "CRITICAL WARNING:" $(VIV_XSA_LOG) && { \
		echo "Critical warnings found. Exiting."; \
		echo "For details see: $(VIV_XSA_LOG)"; \
		exit 1; \
	} || true

.PHONY: xsa_all
xsa_all:
	for targ in $(TARGET_LIST); do \
		$(MAKE) xsa TARGET=$$targ JOBS=$(JOBS); \
	done

.PHONY: project
project: check_target
	@if [ -f $(VIV_LOCK) ]; then \
		echo "$(TARGET) is locked. Skipping..."; \
	else \
		touch $(VIV_LOCK); \
		$(MAKE) project_locked TARGET=$(TARGET) JOBS=$(JOBS); \
		rm -f $(VIV_LOCK); \
	fi

project_locked: $(VIV_XPR)
$(VIV_XPR):
	@echo 'Create Vivado project $(TARGET)'
	$(MKDIR) $(VIV_LOG_DIR)
	$(RM) $(VIV_XPR_LOG) $(VIV_XPR_JOU)
	$(VIVADO) -mode batch -notrace -source $(VIV_SCRIPT_BD) -log $(VIV_XPR_LOG) -journal $(VIV_XPR_JOU) -tclargs $(TARGET)

.PHONY: project_all
project_all:
	for targ in $(TARGET_LIST); do \
		$(MAKE) project TARGET=$$targ JOBS=$(JOBS); \
	done

.PHONY: clean
clean: check_target
	@echo 'Cleaning project $(TARGET)'
	$(RM) $(VIV_DIR)

.PHONY: clean_all
clean_all:
	for targ in $(TARGET_LIST); do \
		$(MAKE) clean TARGET=$$targ; \
	done
	$(RM) .Xil vivado*.log vivado*.jou

check_target:
ifndef $(TARGET)_target
	$(error "Please specify a TARGET. Use 'make help' to see valid targets.")
endif


