# Opsero Electronic Design Inc. 2023
#
# This Makefile can be used to build all projects and gather the boot images.

RM = rm -rf
JOBS ?= 8
ROOT_DIR = $(shell pwd)
BD_NAME = fpgadrv

# default target
TARGET ?= none

VIV_DIR = $(ROOT_DIR)/Vivado
VIV_PRJ_DIR = $(VIV_DIR)/$(TARGET)
VIV_XSA = $(VIV_PRJ_DIR)/$(BD_NAME)_wrapper.xsa
VIV_BIT = $(VIV_PRJ_DIR)/$(TARGET).runs/impl_1/$(BD_NAME)_wrapper.bit

# valid targets (template name)
kc705_hpc_target := microblaze
kc705_lpc_target := microblaze
kcu105_hpc_target := microblaze
kcu105_hpc_dual_target := microblaze
kcu105_lpc_target := microblaze
pz_7015_target := zynq
pz_7030_target := zynq
uzev_dual_target := zynqMP
vcu118_target := microblaze
vcu118_dual_target := microblaze
zc706_hpc_target := zynq
zc706_lpc_target := zynq
zcu104_target := zynqMP
zcu106_hpc0_target := zynqMP
zcu106_hpc0_dual_target := zynqMP
zcu106_hpc1_target := zynqMP
zcu111_target := zynqMP
zcu111_dual_target := zynqMP
zcu208_target := zynqMP
zcu208_dual_target := zynqMP

TARGET_LIST := $(patsubst %_target,%,$(filter %_target,$(.VARIABLES)))

# target board (the first word in the target name, before the first underscore)
TARGET_BOARD=$(word 1,$(subst _, ,$(TARGET)))

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

# outputs
BOOTIMAGE_DIR = $(ROOT_DIR)/bootimages
TEMPBOOT_DIR = $(BOOTIMAGE_DIR)/$(BD_NAME)_$(TARGET)
PETL_ZIP = $(BOOTIMAGE_DIR)/$(BD_NAME)_$(TARGET)_petalinux-2022-1.zip
BARE_ZIP = $(BOOTIMAGE_DIR)/$(BD_NAME)_$(TARGET)_standalone-2022-1.zip

define get_template_name
$($(1)_target)
endef

.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make bootimage TARGET=<val>'
	@echo '    Gather boot image files for given target.'
	@echo ''
	@echo '  make clean'
	@echo '    Clean runs'
	@echo ''
	@echo '  Valid TARGETs:'
	@$(foreach targ,$(TARGET_LIST),echo "    - $(targ)";)
	@echo ''

check_target:
ifndef $(TARGET)_target
	$(error "Please specify a TARGET. Use 'make help' to see valid targets.")
endif

.PHONY: bootimage
bootimage: check_target $(PETL_ZIP)

ifeq ($(call get_template_name,$(TARGET)), microblaze)
$(PETL_ZIP): $(PETL_BOOT_MCS) $(PETL_BOOT_PRM) $(PETL_IMAGE_ELF) $(PETL_SYSTEM_BIT)
	echo 'Gather PetaLinux output products for $(TARGET)'; \
	mkdir -p $(TEMPBOOT_DIR)/flash
	mkdir -p $(TEMPBOOT_DIR)/jtag
	cp $(PETL_BOOT_MCS) $(TEMPBOOT_DIR)/flash/.
	cp $(PETL_BOOT_PRM) $(TEMPBOOT_DIR)/flash/.
	cp $(PETL_IMAGE_ELF) $(TEMPBOOT_DIR)/jtag/.
	cp $(PETL_SYSTEM_BIT) $(TEMPBOOT_DIR)/jtag/.
	echo 'Program the flash with this MCS file to boot from flash' > $(TEMPBOOT_DIR)/flash/readme.txt
	echo 'Load these files via JTAG to boot PetaLinux from JTAG' > $(TEMPBOOT_DIR)/jtag/readme.txt
	cd $(TEMPBOOT_DIR) && zip -r $(PETL_ZIP) .
	rm -r $(TEMPBOOT_DIR)

else ifeq ($(call get_template_name,$(TARGET)), zynq)
$(PETL_ZIP): $(PETL_BOOT_BIN) $(PETL_IMAGE_UB)
	echo 'Gather PetaLinux output products for $(TARGET)'; \
	mkdir -p $(TEMPBOOT_DIR)/boot
	mkdir -p $(TEMPBOOT_DIR)/root
	cp $(PETL_BOOT_BIN) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_IMAGE_UB) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_BOOT_SCR) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_ROOTFS) $(TEMPBOOT_DIR)/root/.
	echo 'Copy these files to the boot (FAT32) partition of the SD card' > $(TEMPBOOT_DIR)/boot/readme.txt
	echo 'Extract contents of rootfs.tar.gz to the root partition of the SD card' > $(TEMPBOOT_DIR)/root/readme.txt
	cd $(TEMPBOOT_DIR) && zip -r $(PETL_ZIP) .
	rm -r $(TEMPBOOT_DIR)

else ifeq ($(call get_template_name,$(TARGET)), zynqMP)
$(PETL_ZIP): $(PETL_BOOT_BIN) $(PETL_IMAGE_UB)
	echo 'Gather PetaLinux output products for $(TARGET)'; \
	mkdir -p $(TEMPBOOT_DIR)/boot
	mkdir -p $(TEMPBOOT_DIR)/root
	cp $(PETL_BOOT_BIN) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_IMAGE_UB) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_BOOT_SCR) $(TEMPBOOT_DIR)/boot/.
	cp $(PETL_ROOTFS) $(TEMPBOOT_DIR)/root/.
	echo 'Copy these files to the boot (FAT32) partition of the SD card' > $(TEMPBOOT_DIR)/boot/readme.txt
	echo 'Extract contents of rootfs.tar.gz to the root partition of the SD card' > $(TEMPBOOT_DIR)/root/readme.txt
	cd $(TEMPBOOT_DIR) && zip -r $(PETL_ZIP) .
	rm -r $(TEMPBOOT_DIR)
endif

$(PETL_BOOT_MCS) $(PETL_BOOT_PRM) $(PETL_IMAGE_ELF) $(PETL_SYSTEM_BIT):
	$(MAKE) -C $(PETL_ROOT) petalinux TARGET=$(TARGET) JOBS=$(JOBS)

$(PETL_BOOT_BIN) $(PETL_IMAGE_UB):
	$(MAKE) -C $(PETL_ROOT) petalinux TARGET=$(TARGET) JOBS=$(JOBS)

.PHONY: clean
clean: check_target
	$(RM) $(TARGET)

