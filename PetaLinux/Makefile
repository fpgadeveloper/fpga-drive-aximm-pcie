# Opsero Electronic Design Inc. 2023
#
# This Makefile can be used to build the PetaLinux projects.

RM = rm -rf
PETL_ROOT = $(shell pwd)
BD_NAME = fpgadrv

# defaults
.DEFAULT_GOAL := petalinux
TARGET ?= none
JOBS ?= 8

# valid targets (template name, flash size, flash interface)
kc705_hpc_target := microblaze 128 BPIx16
kc705_lpc_target := microblaze 128 BPIx16
kcu105_hpc_target := microblaze 32 SPIx4
kcu105_hpc_dual_target := microblaze 32 SPIx4
kcu105_lpc_target := microblaze 32 SPIx4
pz_7015_target := zynq 0 0
pz_7030_target := zynq 0 0
uzev_dual_target := zynqMP 0 0
vck190_fmcp1_target := versal 0 0
vck190_fmcp2_target := versal 0 0
vmk180_fmcp1_target := versal 0 0
vmk180_fmcp2_target := versal 0 0
vcu118_target := microblaze 128 SPIx4
vcu118_dual_target := microblaze 128 SPIx4
zc706_hpc_target := zynq 0 0
zc706_lpc_target := zynq 0 0
zcu104_target := zynqMP 0 0
zcu106_hpc0_target := zynqMP 0 0
zcu106_hpc0_dual_target := zynqMP 0 0
zcu106_hpc1_target := zynqMP 0 0
zcu111_target := zynqMP 0 0
zcu111_dual_target := zynqMP 0 0
zcu208_target := zynqMP 0 0
zcu208_dual_target := zynqMP 0 0

TARGET_LIST := $(sort $(patsubst %_target,%,$(filter %_target,$(.VARIABLES))))

# target board (the first word in the target name, before the first underscore)
TARGET_BOARD=$(word 1,$(subst _, ,$(TARGET)))

# Vivado paths
VIV_DIR = $(PETL_ROOT)/../Vivado
VIV_PRJ_DIR = $(VIV_DIR)/$(TARGET)
VIV_XSA = $(VIV_PRJ_DIR)/$(BD_NAME)_wrapper.xsa
VIV_BIT = $(VIV_PRJ_DIR)/$(TARGET).runs/impl_1/$(BD_NAME)_wrapper.bit

# petalinux paths and files
PETL_DIR = $(PETL_ROOT)/$(TARGET)
PETL_IMG_DIR = $(PETL_DIR)/images/linux
PETL_BL31_ELF = $(PETL_IMG_DIR)/bl31.elf
PETL_PMUFW_ELF = $(PETL_IMG_DIR)/pmufw.elf
PETL_ZYNQMP_FSBL_ELF = $(PETL_IMG_DIR)/zynqmp_fsbl.elf
PETL_ZYNQ_FSBL_ELF = $(PETL_IMG_DIR)/zynq_fsbl.elf
PETL_FSBOOT_ELF = $(PETL_IMG_DIR)/fs-boot.elf
PETL_UBOOT_ELF = $(PETL_IMG_DIR)/u-boot.elf
PETL_DTB = $(PETL_IMG_DIR)/system.dtb
PETL_BOOT_BIN = $(PETL_IMG_DIR)/BOOT.BIN
PETL_BOOT_SCR = $(PETL_IMG_DIR)/boot.scr
PETL_BOOT_MCS = $(PETL_IMG_DIR)/boot.mcs
PETL_ROOTFS = $(PETL_IMG_DIR)/rootfs.tar.gz
PETL_IMAGE_UB = $(PETL_IMG_DIR)/image.ub
PETL_CFG_DONE = $(PETL_DIR)/configdone.txt
PETL_COMP_DIR = $(PETL_DIR)/components
PETL_OFFLINE = $(PETL_ROOT)/offline.txt
PETL_LOCK = $(PETL_ROOT)/.$(TARGET).lock

# These macros return values from the valid target lists defined above
define get_template_name
$(word 1,$($(1)_target))
endef

define get_flash_size
$(word 2,$($(1)_target))
endef

define get_flash_intf
$(word 3,$($(1)_target))
endef

# For offline PetaLinux builds
SSTATE_PATH ?= $(shell test -e $(PETL_OFFLINE) && head -n 1 $(PETL_OFFLINE))

ifeq ($(call get_template_name,$(TARGET)), microblaze)
	SSTATE_ARCH = microblaze
	BUILD_PRODUCTS = $(PETL_FSBOOT_ELF) $(PETL_UBOOT_ELF) $(PETL_DTB)
	PKG_PRODUCTS = $(PETL_BOOT_MCS)
else ifeq ($(call get_template_name,$(TARGET)), zynq)
	SSTATE_ARCH = arm
	BUILD_PRODUCTS = $(PETL_ZYNQ_FSBL_ELF) $(PETL_DTB)
	PKG_PRODUCTS = $(PETL_BOOT_BIN)
else ifeq ($(call get_template_name,$(TARGET)), zynqMP)
	SSTATE_ARCH = arch64
	BUILD_PRODUCTS = $(PETL_BL31_ELF) $(PETL_PMUFW_ELF) $(PETL_ZYNQMP_FSBL_ELF) $(PETL_DTB)
	PKG_PRODUCTS = $(PETL_BOOT_BIN)
else ifeq ($(call get_template_name,$(TARGET)), versal)
	SSTATE_ARCH = arch64
	BUILD_PRODUCTS = $(PETL_BL31_ELF) $(PETL_DTB)
	PKG_PRODUCTS = $(PETL_BOOT_BIN)
endif

ifneq ($(SSTATE_PATH),)
	MIRROR_URL = CONFIG_PRE_MIRROR_URL="file://$(SSTATE_PATH)/downloads"
	SSTATE_FEEDS = CONFIG_YOCTO_LOCAL_SSTATE_FEEDS_URL="$(SSTATE_PATH)/$(SSTATE_ARCH)"
endif

.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make petalinux TARGET=<val> JOBS=<val>'
	@echo '    Build the PetaLinux project for specified target.'
	@echo ''
	@echo '  make all JOBS=<val>'
	@echo '    Build the PetaLinux project for all target designs.'
	@echo ''
	@echo '  make clean TARGET=<val>'
	@echo '    Delete PetaLinux project of specified target.'
	@echo ''
	@echo '  make clean_all'
	@echo '    Delete PetaLinux projects of all targets.'
	@echo ''
	@echo '  make status TARGET=<val>'
	@echo '    Print the status (built,packaged) of the PetaLinux project of specified target.'
	@echo ''
	@echo '  make status_all'
	@echo '    Print status of the PetaLinux projects of all targets.'
	@echo ''
	@echo 'Parameters:'
	@echo ''
	@echo '  TARGET: Name of the target design, must be one of the following:'
	@$(foreach targ,$(TARGET_LIST),echo "    - $(targ)";)
	@echo ''
	@echo '  JOBS: Optional param to set number of synthesis jobs (default 8)'
	@echo ''
	@echo 'Example usage:'
	@echo '  make petalinux TARGET=$(word 1,$(TARGET_LIST))'
	@echo ''

.PHONY: petalinux
petalinux: check_target
	@if [ -f $(PETL_LOCK) ]; then \
		echo "$(TARGET) is locked. Skipping..."; \
	else \
		touch $(PETL_LOCK); \
		$(MAKE) --no-print-directory petalinux_locked TARGET=$(TARGET) JOBS=$(JOBS); \
		rm -f $(PETL_LOCK); \
	fi

petalinux_locked: package

# Package rule for microblaze designs
ifeq ($(call get_template_name,$(TARGET)), microblaze)
package: $(PKG_PRODUCTS)
$(PKG_PRODUCTS): $(BUILD_PRODUCTS)
	@echo 'Packaging PetaLinux project for $(TARGET)'
	cd $(TARGET) && petalinux-package --boot --force --fpga $(VIV_BIT) --u-boot --kernel --flash-size $(call get_flash_size,$(TARGET)) --flash-intf $(call get_flash_intf,$(TARGET))
	
# Package rule for zynq designs
else ifeq ($(call get_template_name,$(TARGET)), zynq)
package: $(PKG_PRODUCTS)
$(PKG_PRODUCTS): $(BUILD_PRODUCTS)
	@echo 'Packaging PetaLinux project for $(TARGET)'
	cd $(TARGET) && petalinux-package --boot --fsbl ./images/linux/zynq_fsbl.elf --fpga $(VIV_BIT) --u-boot
	
# Package rule for zynqMP designs
else ifeq ($(call get_template_name,$(TARGET)), zynqMP)
package: $(PKG_PRODUCTS)
$(PKG_PRODUCTS): $(BUILD_PRODUCTS)
	@echo 'Packaging PetaLinux project for $(TARGET)'
	cd $(TARGET) && petalinux-package --boot --fsbl ./images/linux/zynqmp_fsbl.elf --fpga $(VIV_BIT) --u-boot
	
# Package rule for versal designs
else ifeq ($(call get_template_name,$(TARGET)), versal)
package: $(PKG_PRODUCTS)
$(PKG_PRODUCTS): $(BUILD_PRODUCTS)
	@echo 'Packaging PetaLinux project for $(TARGET)'
	cd $(TARGET) && petalinux-package --boot --plm --psmfw --u-boot --dtb
endif

$(BUILD_PRODUCTS): $(PETL_CFG_DONE)
	cd $(TARGET) && petalinux-build

$(PETL_CFG_DONE): | $(PETL_COMP_DIR)
	cp -R ./bsp/$(TARGET_BOARD)/project-spec ./$(TARGET)/.
	@if [ ! -z "$(SSTATE_PATH)" ]; then \
		echo '$(MIRROR_URL)' >> ./$(TARGET)/project-spec/configs/config; \
		echo '$(SSTATE_FEEDS)' >> ./$(TARGET)/project-spec/configs/config; \
		echo 'Configuring project for offline build ($(SSTATE_PATH))'; \
	fi
	touch $(TARGET)/configdone.txt
	cd $(TARGET) && petalinux-config --silentconfig
	
$(PETL_COMP_DIR): | $(PETL_DIR)
	cd $(TARGET) && petalinux-config --get-hw-description $(VIV_XSA) --silentconfig
	
$(PETL_DIR): $(VIV_XSA)
	@if [ -d $@ ]; then echo "Project $(TARGET) already exists but is outdated. Use 'make clean TARGET=$(TARGET)' to remove it."; exit 1; fi
	petalinux-create --type project --template $(call get_template_name,$(TARGET)) --name $(TARGET)

$(VIV_XSA):
	$(MAKE) -C $(VIV_DIR) xsa TARGET=$(TARGET) JOBS=$(JOBS)

.PHONY: all
all:
	@{ \
	for targ in $(TARGET_LIST); do \
		$(MAKE) --no-print-directory petalinux TARGET=$${targ} JOBS=$(JOBS); \
	done; \
	}

.PHONY: clean
clean: check_target
	$(RM) $(TARGET)

.PHONY: clean_all
clean_all:
	for targ in $(TARGET_LIST); do \
		$(MAKE) --no-print-directory clean TARGET=$$targ; \
	done

.PHONY: status
status: check_target
	@{ \
	all_built=true; \
	for file in $(BUILD_PRODUCTS); do \
		if [ ! -e $$file ]; then \
			printf 'Target %-20s: **NOT BUILT** & ' "$(TARGET)"; \
			all_built=false; \
			break; \
		fi; \
	done; \
	if $$all_built; then \
		printf 'Target %-20s: BUILT & ' "$(TARGET)"; \
	fi; \
	all_built=true; \
	for file in $(PKG_PRODUCTS); do \
		if [ ! -e $$file ]; then \
			printf '**NOT PACKAGED**\n'; \
			all_built=false; \
			break; \
		fi; \
	done; \
	if $$all_built; then \
		printf 'PACKAGED\n'; \
	fi; \
	}

.PHONY: status_all
status_all:
	@{ \
	for targ in $(TARGET_LIST); do \
		$(MAKE) --no-print-directory status TARGET=$$targ; \
	done; \
	}

check_target:
ifndef $(TARGET)_target
	$(error "Please specify a TARGET. Use 'make help' to see valid targets.")
endif


