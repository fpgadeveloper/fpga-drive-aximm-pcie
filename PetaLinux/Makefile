# Opsero Electronic Design Inc. 2023
#
# This Makefile can be used to build the PetaLinux projects.

RM = rm -rf
VIVADO = $(XILINX_VIVADO)/bin/vivado
JOBS ?= 8
PETL_ROOT = $(shell pwd)
BD_NAME = fpgadrv

# default target
TARGET ?= none

VIV_DIR = $(PETL_ROOT)/../Vivado
VIV_PRJ_DIR = $(VIV_DIR)/$(TARGET)
VIV_XSA = $(VIV_PRJ_DIR)/$(BD_NAME)_wrapper.xsa
VIV_BIT = $(VIV_PRJ_DIR)/$(TARGET).runs/impl_1/$(BD_NAME)_wrapper.bit

# valid targets
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
PETL_DIR = $(PETL_ROOT)/$(TARGET)
PETL_IMG_DIR = $(PETL_DIR)/images/linux
PETL_BL31_ELF = $(PETL_IMG_DIR)/bl31.elf
PETL_PMUFW_ELF = $(PETL_IMG_DIR)/pmufw.elf
PETL_FSBL_ELF = $(PETL_IMG_DIR)/zynqmp_fsbl.elf
PETL_DTB = $(PETL_IMG_DIR)/system.dtb
PETL_BOOT_BIN = $(PETL_IMG_DIR)/BOOT.BIN
PETL_BOOT_SCR = $(PETL_IMG_DIR)/boot.scr
PETL_ROOTFS = $(PETL_IMG_DIR)/rootfs.tar.gz
PETL_IMAGE_UB = $(PETL_IMG_DIR)/image.ub
PETL_CFG_DONE = $(PETL_DIR)/configdone.txt
PETL_COMP_DIR = $(PETL_DIR)/components
PETL_ZIP = $(PETL_DIR)/$(TARGET_BOARD)_$(TARGET)_petalinux-2022-1.zip
PETL_SDCARD_DIR = $(PETL_DIR)/sdcard

define get_template_name
$($(1)_target)
endef

.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make sdcard TARGET=<val>'
	@echo '    Gather PetaLinux output products for the SD card.'
	@echo ''
	@echo '  make petalinux TARGET=<val>'
	@echo '    Build the PetaLinux project.'
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

.PHONY: sdcard
sdcard: check_target $(PETL_ZIP)
$(PETL_ZIP): $(PETL_BOOT_BIN) $(PETL_IMAGE_UB)
	echo 'Gather PetaLinux output products for $(TARGET)'; \
	mkdir -p $(PETL_SDCARD_DIR)/boot
	mkdir -p $(PETL_SDCARD_DIR)/root
	cp $(PETL_BOOT_BIN) $(PETL_SDCARD_DIR)/boot/.
	cp $(PETL_IMAGE_UB) $(PETL_SDCARD_DIR)/boot/.
	cp $(PETL_BOOT_SCR) $(PETL_SDCARD_DIR)/boot/.
	cp $(PETL_ROOTFS) $(PETL_SDCARD_DIR)/root/.
	echo 'Copy these files to the boot (FAT32) partition of the SD card' > $(PETL_SDCARD_DIR)/boot/readme.txt
	echo 'Extract contents of rootfs.tar.gz to the root partition of the SD card' > $(PETL_SDCARD_DIR)/root/readme.txt
	cd $(PETL_SDCARD_DIR) && zip -r $(PETL_ZIP) .

.PHONY: petalinux
petalinux: check_target package_$(call get_template_name,$(TARGET))

package_microblaze: build
	echo 'Packaging PetaLinux project for $(TARGET)'; \
	cd $(TARGET) && petalinux-package --boot --force --fpga $(VIV_BIT) --u-boot --kernel
	
package_zynq: build
	echo 'Packaging PetaLinux project for $(TARGET)'; \
	cd $(TARGET) && petalinux-package --boot --fsbl ./images/linux/zynq_fsbl.elf --fpga $(VIV_BIT) --u-boot
	
package_zynqMP: build
	echo 'Packaging PetaLinux project for $(TARGET)'; \
	cd $(TARGET) && petalinux-package --boot --fsbl ./images/linux/zynqmp_fsbl.elf --fpga $(VIV_BIT) --u-boot
	
build: $(PETL_CFG_DONE)
	cd $(TARGET) && petalinux-build

$(PETL_CFG_DONE): | $(PETL_COMP_DIR)
	cp -R ./bsp/$(TARGET_BOARD)/project-spec ./$(TARGET)/.
	touch $(TARGET)/configdone.txt
	cd $(TARGET) && petalinux-config --silentconfig
	
$(PETL_COMP_DIR): | $(PETL_DIR)
	cd $(TARGET) && petalinux-config --get-hw-description $(VIV_XSA) --silentconfig
	
$(PETL_DIR): $(VIV_XSA)
	petalinux-create --type project --template $(call get_template_name,$(TARGET)) --name $(TARGET)

$(VIV_XSA):
	$(MAKE) -C $(VIV_DIR) xsa TARGET=$(TARGET) JOBS=$(JOBS)

.PHONY: clean
clean: check_target
	$(RM) $(TARGET)

