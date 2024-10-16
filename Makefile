# Opsero Electronic Design Inc. 2024
#
# This Makefile can be used to build all projects and gather the boot images.

RM = rm -rf
ROOT_DIR = $(shell pwd)
BD_NAME = fpgadrv

# defaults
.DEFAULT_GOAL := bootimage
TARGET ?= none
JOBS ?= 8

# valid targets (template name, both (plnx+baremetal) or baremetal_only)
auboard_target := microblaze both
kc705_hpc_target := microblaze both
kc705_lpc_target := microblaze both
kcu105_hpc_target := microblaze both
kcu105_lpc_target := microblaze both
pz_7015_target := zynq both
pz_7030_target := zynq both
uzev_target := zynqMP both
vc707_hpc1_target := microblaze baremetal_only
vc707_hpc2_target := microblaze baremetal_only
vc709_hpc_target := microblaze baremetal_only
vck190_fmcp1_target := versal both
vck190_fmcp2_target := versal both
vmk180_fmcp1_target := versal both
vmk180_fmcp2_target := versal both
vpk120_target := versal both
vpk180_target := versal both
vcu118_target := microblaze both
zc706_hpc_target := zynq both
zc706_lpc_target := zynq both
zcu104_target := zynqMP both
zcu106_hpc0_target := zynqMP both
zcu106_hpc1_target := zynqMP both
zcu111_target := zynqMP both
zcu208_target := zynqMP both

TARGET_LIST := $(sort $(patsubst %_target,%,$(filter %_target,$(.VARIABLES))))

# petalinux paths and files
PETL_ROOT = $(ROOT_DIR)/PetaLinux
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
PETL_BOOT_PRM = $(PETL_IMG_DIR)/boot.prm
PETL_IMAGE_ELF = $(PETL_IMG_DIR)/image.elf
PETL_SYSTEM_BIT = $(PETL_IMG_DIR)/system.bit
PETL_ROOTFS = $(PETL_IMG_DIR)/rootfs.tar.gz
PETL_IMAGE_UB = $(PETL_IMG_DIR)/image.ub

# vitis paths and files
VIT_ROOT = $(ROOT_DIR)/Vitis
VIT_BOOT = $(VIT_ROOT)/boot
VIT_BOOT_TARG = $(VIT_BOOT)/$(TARGET)

# outputs
BOOTIMAGE_DIR = $(ROOT_DIR)/bootimages
TEMPBOOT_DIR = $(BOOTIMAGE_DIR)/$(BD_NAME)_$(TARGET)
PETL_ZIP = $(BOOTIMAGE_DIR)/$(BD_NAME)_$(TARGET)_petalinux-2022-1.zip
BARE_ZIP = $(BOOTIMAGE_DIR)/$(BD_NAME)_$(TARGET)_standalone-2022-1.zip
BOOTIMAGE_LOCK = $(ROOT_DIR)/.$(TARGET).lock

# These macros return values from the valid target lists defined above
define get_template_name
$(word 1,$($(1)_target))
endef

define get_both_or_baremetal_only
$(word 2,$($(1)_target))
endef

# The name of the boot image of the baremetal app depends on the device
ifeq ($(call get_template_name,$(TARGET)), microblaze)
	VIT_BOOT_FILE = $(VIT_BOOT_TARG)/$(TARGET).bit
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
	@echo '  make bootimage TARGET=<val> JOBS=<val>'
	@echo '    Build and gather boot image files for given target.'
	@echo ''
	@echo '  make all JOBS=<val>'
	@echo '    Build and gather boot image files for all targets.'
	@echo ''
	@echo '  make clean TARGET=<val>'
	@echo '    Delete boot image files for given target.'
	@echo ''
	@echo '  make clean_all'
	@echo '    Delete boot image files for all targets.'
	@echo ''
	@echo 'Parameters:'
	@echo ''
	@echo '  TARGET: Name of the target design, must be one of the following:'
	@$(foreach targ,$(TARGET_LIST),echo "    - $(targ)";)
	@echo ''
	@echo '  JOBS: Optional param to set number of synthesis jobs (default 8)'
	@echo ''
	@echo 'Example usage:'
	@echo '  make bootimage TARGET=$(word 1,$(TARGET_LIST))'
	@echo ''


.PHONY: all
all:
	@{ \
	for targ in $(TARGET_LIST); do \
		$(MAKE) --no-print-directory bootimage TARGET=$${targ} JOBS=$(JOBS); \
	done; \
	}

.PHONY: bootimage
bootimage: check_target
	@if [ -f $(BOOTIMAGE_LOCK) ]; then \
		echo "$(TARGET) is locked. Skipping..."; \
	else \
		touch $(BOOTIMAGE_LOCK); \
		$(MAKE) bootimage_locked TARGET=$(TARGET) JOBS=$(JOBS); \
		rm -f $(BOOTIMAGE_LOCK); \
	fi

bootimage_locked: bootimage_$(call get_both_or_baremetal_only,$(TARGET))

bootimage_baremetal_only: $(BARE_ZIP)

bootimage_both: $(PETL_ZIP) $(BARE_ZIP)

ifeq ($(call get_template_name,$(TARGET)), microblaze)
$(PETL_ZIP): $(PETL_BOOT_MCS) $(PETL_BOOT_PRM) $(PETL_IMAGE_ELF) $(PETL_SYSTEM_BIT)
	@echo 'Gather PetaLinux output products for $(TARGET)'
	mkdir -p $(TEMPBOOT_DIR)/flash
	mkdir -p $(TEMPBOOT_DIR)/jtag
	cp $(PETL_BOOT_MCS) $(TEMPBOOT_DIR)/flash/.
	cp $(PETL_BOOT_PRM) $(TEMPBOOT_DIR)/flash/.
	cp $(PETL_IMAGE_ELF) $(TEMPBOOT_DIR)/jtag/.
	cp $(PETL_SYSTEM_BIT) $(TEMPBOOT_DIR)/jtag/.
	@echo 'Program the flash with this MCS file to boot from flash' > $(TEMPBOOT_DIR)/flash/readme.txt
	@echo 'Load these files via JTAG to boot PetaLinux from JTAG' > $(TEMPBOOT_DIR)/jtag/readme.txt
	cd $(TEMPBOOT_DIR) && zip -r $(PETL_ZIP) .
	rm -r $(TEMPBOOT_DIR)

else ifeq ($(call get_template_name,$(TARGET)), zynq)
$(PETL_ZIP): $(PETL_BOOT_BIN) $(PETL_IMAGE_UB)
	@echo 'Gather PetaLinux output products for $(TARGET)'
	mkdir -p $(TEMPBOOT_DIR)/boot
	mkdir -p $(TEMPBOOT_DIR)/root
	cp $(PETL_BOOT_BIN) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_IMAGE_UB) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_BOOT_SCR) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_ROOTFS) $(TEMPBOOT_DIR)/root/.
	@echo 'Copy these files to the boot (FAT32) partition of the SD card' > $(TEMPBOOT_DIR)/boot/readme.txt
	@echo 'Extract contents of rootfs.tar.gz to the root partition of the SD card' > $(TEMPBOOT_DIR)/root/readme.txt
	cd $(TEMPBOOT_DIR) && zip -r $(PETL_ZIP) .
	rm -r $(TEMPBOOT_DIR)

else ifeq ($(call get_template_name,$(TARGET)), zynqMP)
$(PETL_ZIP): $(PETL_BOOT_BIN) $(PETL_IMAGE_UB)
	@echo 'Gather PetaLinux output products for $(TARGET)'
	mkdir -p $(TEMPBOOT_DIR)/boot
	mkdir -p $(TEMPBOOT_DIR)/root
	cp $(PETL_BOOT_BIN) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_IMAGE_UB) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_BOOT_SCR) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_ROOTFS) $(TEMPBOOT_DIR)/root/.
	@echo 'Copy these files to the boot (FAT32) partition of the SD card' > $(TEMPBOOT_DIR)/boot/readme.txt
	@echo 'Extract contents of rootfs.tar.gz to the root partition of the SD card' > $(TEMPBOOT_DIR)/root/readme.txt
	cd $(TEMPBOOT_DIR) && zip -r $(PETL_ZIP) .
	rm -r $(TEMPBOOT_DIR)

else ifeq ($(call get_template_name,$(TARGET)), versal)
$(PETL_ZIP): $(PETL_BOOT_BIN) $(PETL_IMAGE_UB)
	@echo 'Gather PetaLinux output products for $(TARGET)'
	mkdir -p $(TEMPBOOT_DIR)/boot
	mkdir -p $(TEMPBOOT_DIR)/root
	cp $(PETL_BOOT_BIN) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_IMAGE_UB) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_BOOT_SCR) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_ROOTFS) $(TEMPBOOT_DIR)/root/.
	@echo 'Copy these files to the boot (FAT32) partition of the SD card' > $(TEMPBOOT_DIR)/boot/readme.txt
	@echo 'Extract contents of rootfs.tar.gz to the root partition of the SD card' > $(TEMPBOOT_DIR)/root/readme.txt
	cd $(TEMPBOOT_DIR) && zip -r $(PETL_ZIP) .
	rm -r $(TEMPBOOT_DIR)
endif

PETL_BUILD_DEPS = $(PETL_BOOT_MCS) $(PETL_BOOT_PRM) $(PETL_IMAGE_ELF) $(PETL_SYSTEM_BIT) \
                  $(PETL_BOOT_BIN) $(PETL_IMAGE_UB)

$(PETL_BUILD_DEPS):
	$(MAKE) --no-print-directory -C $(PETL_ROOT) petalinux TARGET=$(TARGET) JOBS=$(JOBS)

$(BARE_ZIP): $(VIT_BOOT_FILE)
	@echo 'Gather standalone application output products for $(TARGET)'
	mkdir -p $(BOOTIMAGE_DIR)
	cd $(VIT_BOOT_TARG) && zip -r $(BARE_ZIP) .

$(VIT_BOOT_FILE):
	$(MAKE) --no-print-directory -C $(VIT_ROOT) workspace TARGET=$(TARGET) JOBS=$(JOBS)
	@if [ ! -e $@ ]; then echo "Error: $@ was not created for $(TARGET)."; exit 1; fi

.PHONY: clean
clean: check_target
	$(RM) $(PETL_ZIP) $(BARE_ZIP)

.PHONY: clean_all
clean_all: 
	$(RM) $(BOOTIMAGE_DIR)

check_target:
ifndef $(TARGET)_target
	$(error "Please specify a TARGET. Use 'make help' to see valid targets.")
endif


