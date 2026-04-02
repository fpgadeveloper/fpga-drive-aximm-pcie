# Opsero Electronic Design Inc. 2025
#
# This Makefile can be used to build the Vitis workspace.

CP = cp -rf
MKDIR = mkdir -p
RM = rm -rf
ROOT_DIR = $(shell pwd)
BD_NAME = fpgadrv
ARGS_JSON = py/args.json
DATA_JSON = ../docs/source/data.json

# defaults
.DEFAULT_GOAL := workspace
TARGET ?= none
JOBS ?= 8

# valid targets
# UPDATER START
auboard_target := microblaze
kc705_hpc_target := microblaze
kc705_lpc_target := microblaze
kcu105_hpc_target := microblaze
kcu105_lpc_target := microblaze
pz_7015_target := zynq
pz_7030_target := zynq
uzev_target := zynqMP
vc707_hpc1_target := microblaze
vc707_hpc2_target := microblaze
vc709_hpc_target := microblaze
vck190_fmcp1_target := versal
vck190_fmcp2_target := versal
vhk158_target := versal
vmk180_fmcp1_target := versal
vmk180_fmcp2_target := versal
vek280_target := versal
vpk120_target := versal
vpk180_target := versal
vcu118_target := microblaze
zc706_hpc_target := zynq
zc706_lpc_target := zynq
zcu104_target := zynqMP
zcu106_hpc0_target := zynqMP
zcu106_hpc1_target := zynqMP
zcu111_target := zynqMP
zcu208_target := zynqMP
zcu216_target := zynqMP
# UPDATER END

TARGET_LIST := $(sort $(patsubst %_target,%,$(filter %_target,$(.VARIABLES))))

# Vitis paths
VIT_SCRIPT_WS   = py/build-vitis.py
VIT_SCRIPT_BOOT = py/make-boot.py
VIT_TARGET_WS   = $(ROOT_DIR)/$(TARGET)_workspace
VIT_LOCK        = $(ROOT_DIR)/.$(TARGET).lock
VIT_BOOT        = $(ROOT_DIR)/boot
VIT_BOOT_TARG   = $(VIT_BOOT)/$(TARGET)

# Vivado paths
VIV_DIR     = $(ROOT_DIR)/../Vivado
VIV_PRJ_DIR = $(VIV_DIR)/$(TARGET)
VIV_XSA     = $(VIV_PRJ_DIR)/$(BD_NAME)_wrapper.xsa

# These macros return values from the valid target lists defined above
define get_template_name
$(word 1,$($(1)_target))
endef

# The name of the boot image depends on the device family.
ifeq ($(call get_template_name,$(TARGET)), microblaze)
	VIT_BOOT_FILE = $(VIT_BOOT_TARG)/$(BD_NAME)_boot.bit
else ifeq ($(call get_template_name,$(TARGET)), zynq)
	VIT_BOOT_FILE = $(VIT_BOOT_TARG)/BOOT.BIN
else ifeq ($(call get_template_name,$(TARGET)), zynqMP)
	VIT_BOOT_FILE = $(VIT_BOOT_TARG)/BOOT.BIN
else ifeq ($(call get_template_name,$(TARGET)), versal)
	VIT_BOOT_FILE = $(VIT_BOOT_TARG)/BOOT.BIN
endif

.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make workspace TARGET=<target> JOBS=<val>'
	@echo '    Create the Vitis workspace and add applications for specified target.'
	@echo ''
	@echo '  make all JOBS=<val>'
	@echo '    Create the Vitis workspace and add applications for all targets.'
	@echo ''
	@echo '  make bootfile TARGET=<target>'
	@echo '    Generate a boot image for the specified target (bit or BOOT.BIN).'
	@echo ''
	@echo '  make clean TARGET=<target>'
	@echo '    Delete the Vitis workspace and all applications for specified target.'
	@echo ''
	@echo '  make clean_all'
	@echo '    Delete all Vitis workspaces and all applications.'
	@echo ''
	@echo 'Parameters:'
	@echo ''
	@echo '  TARGET: Name of the target design, must be one of the following:'
	@$(foreach targ,$(TARGET_LIST),echo "    - $(targ)";)
	@echo ''
	@echo '  JOBS: Optional param to set number of synthesis jobs (default 8)'
	@echo ''
	@echo 'Example usage:'
	@echo '  make workspace TARGET=$(word 1,$(TARGET_LIST))'
	@echo '  make bootfile  TARGET=$(word 1,$(TARGET_LIST))'
	@echo ''

.PHONY: all
all:
	@{ \
	for targ in $(TARGET_LIST); do \
		$(MAKE) --no-print-directory bootfile TARGET=$$targ; \
	done; \
	}

.PHONY: workspace
workspace: check_target
	@if [ -f $(VIT_LOCK) ]; then \
		echo "$(TARGET) is locked. Skipping..."; \
	else \
		touch $(VIT_LOCK); \
		$(MAKE) workspace_locked TARGET=$(TARGET) JOBS=$(JOBS); \
		rm -f $(VIT_LOCK); \
	fi

workspace_locked: $(VIT_TARGET_WS)

$(VIT_TARGET_WS): $(VIV_XSA)
	@if [ -d $@ ]; then echo "Workspace for $(TARGET) already exists but is outdated. Use 'make clean TARGET=$(TARGET)' to remove it."; exit 1; fi
	vitis -source $(VIT_SCRIPT_WS) $(TARGET) $(ARGS_JSON) $(DATA_JSON)

$(VIV_XSA):
	$(MAKE) -C $(VIV_DIR) xsa TARGET=$(TARGET) JOBS=$(JOBS)

# --------------------------------------------------------------------
# Bootfile generation
# --------------------------------------------------------------------
.PHONY: bootfile
bootfile: check_target
	@if [ -f $(VIT_LOCK) ]; then \
		echo "$(TARGET) is locked. Skipping..."; \
	else \
		touch $(VIT_LOCK); \
		$(MAKE) --no-print-directory bootfile_locked TARGET=$(TARGET) JOBS=$(JOBS); \
		rm -f $(VIT_LOCK); \
	fi

bootfile_locked:
	@{ \
	  if [ ! -d "$(VIT_TARGET_WS)" ]; then \
	    echo "Workspace for $(TARGET) not found — creating it first..."; \
	    $(MAKE) --no-print-directory workspace_locked TARGET=$(TARGET) JOBS=$(JOBS) || exit $$?; \
	  fi; \
	  echo "Generating bootfile for $(TARGET) ..."; \
	  vitis -source $(VIT_SCRIPT_BOOT) $(TARGET) $(ARGS_JSON) $(DATA_JSON) || exit $$?; \
	  echo ""; \
	  echo "Boot outputs are in: $(VIT_BOOT_TARG)"; \
	  if [ "$(call get_template_name,$(TARGET))" = "microblaze" ]; then \
	    echo "  (MB) Possible files:"; \
	    echo "    - $(VIT_BOOT_TARG)/$(BD_NAME)_boot.bit   (combine_bit_elf=true)"; \
	    echo "    - $(VIT_BOOT_TARG)/$(BD_NAME).bit        (combine_bit_elf=false)"; \
	  else \
	    echo "  (PS) Expected file:"; \
	    echo "    - $(VIT_BOOT_TARG)/BOOT.BIN"; \
	  fi; \
	}

.PHONY: clean
clean: check_target
	$(RM) $(TARGET)_workspace

.PHONY: clean_all
clean_all:
	@{ \
	for targ in $(TARGET_LIST); do \
		$(RM) $${targ}_workspace; \
	done; \
	$(RM) boot .Xil RemoteSystemsTempFiles; \
	}

check_target:
ifndef $(TARGET)_target
	$(error "Please specify a TARGET. Use 'make help' to see valid targets.")
endif
