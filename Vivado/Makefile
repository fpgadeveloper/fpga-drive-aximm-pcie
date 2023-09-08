# Opsero Electronic Design Inc. 2023
#
# This Makefile can be used to build these projects from sources.

CP = cp -rf
MKDIR = mkdir -p
RM = rm -rf
XSCT = $(XILINX_VITIS)/bin/xsct
VIVADO = $(XILINX_VIVADO)/bin/vivado
BD_NAME = fpgadrv

# default number of jobs
JOBS ?= 8

# valid targets
TARGET_LIST = kc705_hpc \
	kc705_lpc \
	kcu105_hpc \
	kcu105_hpc_dual \
	kcu105_lpc \
	pz7z015_lpc \
	pz7z030_lpc \
	uzev_dual \
	vc707_hpc1 \
	vc707_hpc2 \
	vc709_hpc \
	vcu118 \
	vcu118_dual \
	zc706_hpc \
	zc706_lpc \
	zcu104 \
	zcu106_hpc0 \
	zcu106_hpc0_dual \
	zcu106_hpc1 \
	zcu111 \
	zcu111_dual \
	zcu208 \
	zcu208_dual

# default target
TARGET ?= none

VIV_SCRIPT_BD = scripts/build.tcl
VIV_SCRIPT_XSA = scripts/xsa.tcl
VIV_DIR = $(TARGET)

# source files
VIV_SRC_XDC = src/

# output files
VIV_XPR = $(VIV_DIR)/$(TARGET).xpr
VIV_XSA = $(VIV_DIR)/$(BD_NAME)_wrapper.xsa
VIV_XPR_LOG = $(TARGET)_xpr.log
VIV_XPR_JOU = $(TARGET)_xpr.jou
VIV_XSA_LOG = $(TARGET)_xsa.log
VIV_XSA_JOU = $(TARGET)_xsa.jou
VIV_BD = $(VIV_DIR)/$(TARGET).srcs/sources_1/bd/$(BD_NAME)/$(BD_NAME).bd
VIV_BIT = $(VIV_DIR)/$(TARGET).runs/impl_1/$(BD_NAME)_wrapper.bit

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
	@echo '  Valid TARGET: ${TARGET_LIST}'
	@echo '  Valid JOBS: optional param to set number of synthesis jobs (default 8)'
	@echo ''

.PHONY: all
all: xsa_all

.PHONY: xsa
xsa: $(VIV_XSA) check_warnings
$(VIV_XSA): $(VIV_XPR)
	$(RM) $(VIV_XSA_LOG) $(VIV_XSA_JOU)
	$(VIVADO) -mode batch -notrace -source $(VIV_SCRIPT_XSA) -log $(VIV_XSA_LOG) -journal $(VIV_XSA_JOU) -tclargs $(TARGET) $(JOBS)
	$(CP) $(VIV_XSA_LOG) $(VIV_XSA_JOU) $(TARGET)/.
	$(RM) $(VIV_XSA_LOG) $(VIV_XSA_JOU)

check_warnings:
	@grep "CRITICAL WARNING:" $(TARGET)/$(VIV_XSA_LOG) && { \
		echo "Critical warnings found. Exiting."; \
		echo "For details see: $(TARGET)/$(VIV_XSA_LOG)"; \
		exit 1; \
	} || true

.PHONY: xsa_all
xsa_all:
	for targ in $(TARGET_LIST); do \
		$(MAKE) xsa TARGET=$$targ JOBS=$(JOBS); \
	done

.PHONY: project
project: $(VIV_XPR)
$(VIV_XPR):
	@valid=0; \
	for p in $(TARGET_LIST); do \
	  if [ "$$p" = "$(TARGET)" ]; then \
	    valid=1; \
	    break; \
	  fi \
	done; \
	if [ "$$valid" -ne 1 ]; then \
	  echo 'Valid target required; you specified: TARGET=$(TARGET).'; \
	  echo 'Example: make project TARGET=$(word 1,$(TARGET_LIST))'; \
	  echo 'Valid TARGETs: $(TARGET_LIST)'; \
	  exit 1; \
	fi; \
	echo 'Create Vivado project $(TARGET)'; \
	$(RM) $(VIV_XPR_LOG) $(VIV_XPR_JOU)
	$(VIVADO) -mode batch -notrace -source $(VIV_SCRIPT_BD) -log $(VIV_XPR_LOG) -journal $(VIV_XPR_JOU) -tclargs $(TARGET)
	$(CP) $(VIV_XPR_LOG) $(VIV_XPR_JOU) $(TARGET)/.
	$(RM) $(VIV_XPR_LOG) $(VIV_XPR_JOU)

.PHONY: project_all
project_all:
	for targ in $(TARGET_LIST); do \
		$(MAKE) project TARGET=$$targ; \
	done

.PHONY: clean
clean:
	@valid=0; \
	for p in $(TARGET_LIST); do \
	  if [ "$$p" = "$(TARGET)" ]; then \
	    valid=1; \
	    break; \
	  fi \
	done; \
	if [ "$$valid" -ne 1 ]; then \
	  echo 'Valid target required; you specified: TARGET=$(TARGET).'; \
	  echo 'Example usage: make clean TARGET=$(word 1,$(TARGET_LIST))'; \
	  echo 'Valid TARGETs: $(TARGET_LIST)'; \
	  exit 1; \
	fi; \
	echo 'Cleaning project $(TARGET)'; \
	$(RM) $(VIV_DIR)

.PHONY: clean_all
clean_all:
	for targ in $(TARGET_LIST); do \
		$(MAKE) clean TARGET=$$targ; \
	done
	$(RM) .Xil vivado*.log vivado*.jou

