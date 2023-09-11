# Opsero Electronic Design Inc. 2023
#
# This Makefile can be used to build the Vitis workspace.

CP = cp -rf
MKDIR = mkdir -p
RM = rm -rf
XSCT = $(XILINX_VITIS)/bin/xsct

APP_POSTFIX = _app
SYS_POSTFIX = $(APP_POSTFIX)_system

VIT_SCRIPT_WS = tcl/build-vitis.tcl

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

.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make workspace'
	@echo '    Create the Vitis workspace and add applications for all exported targets.'
	@echo ''
	@echo '  make clean'
	@echo '    Delete the Vitis workspace and all applications.'
	@echo ''

.PHONY: all
all: workspace

.PHONY: workspace
workspace:
	$(XSCT) $(VIT_SCRIPT_WS)

.PHONY: clean
clean:
	for targ in $(TARGET_LIST); do \
		$(RM) $${targ} $${targ}$(APP_POSTFIX) $${targ}$(SYS_POSTFIX); \
	done
	$(RM) boot .metadata .Xil IDE.log .analytics updatemem*.jou updatemem*.log

