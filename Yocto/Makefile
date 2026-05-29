# Opsero Electronic Design Inc. 2025
#
# This Makefile can be used to build Linux images using the AMD Yocto / EDF
# flow (the announced successor to PetaLinux Tools). It mirrors the layout
# and target naming used by ../PetaLinux/Makefile.
#
# Per-target workspace layout (created on first build):
#   <TARGET>/.repo/        - manifest tooling from Google's `repo`
#   <TARGET>/sources/      - all Yocto layers (poky, meta-xilinx, meta-amd-edf, ...)
#   <TARGET>/setupsdk      - environment setup script provided by yocto-manifests
#   <TARGET>/build/        - bitbake build dir (conf/, tmp/, sstate-cache/)
#   <TARGET>/images/linux/ - gathered output products (BOOT.BIN, image.ub, rootfs, wic)
#
# Source layers come from github.com/Xilinx/yocto-manifests rel-v2025.2,
# manifest `default-edf.xml`. No login required for sources; offline.txt
# (if present) points at a directory containing a downloaded aarch64
# sstate-cache for faster builds.

RM = rm -rf
YOCTO_ROOT = $(shell pwd)
BD_NAME = fpgadrv

# defaults
.DEFAULT_GOAL := yocto
TARGET ?= none
JOBS ?= 8

# Yocto manifest source (Google `repo` tool)
YOCTO_MANIFEST_URL = https://github.com/Xilinx/yocto-manifests.git
YOCTO_MANIFEST_BRANCH = rel-v2025.2
YOCTO_MANIFEST_FILE = default-edf.xml
YOCTO_IMAGE_RECIPE = edf-linux-disk-image

# valid targets (template name)
# UPDATER START
zcu104_target := zynqMP
zcu106_hpc0_target := zynqMP
zcu106_hpc1_target := zynqMP
zcu111_target := zynqMP
zcu208_target := zynqMP
# UPDATER END

TARGET_LIST := $(sort $(patsubst %_target,%,$(filter %_target,$(.VARIABLES))))

# target board (the first word in the target name, before the first underscore)
TARGET_BOARD = $(word 1,$(subst _, ,$(TARGET)))

# Build flow per target.
#   gen-machineconf   - AMD's recommended `parse-sdt` path: generate a custom
#                       MACHINE (PS + PL device tree) directly from the project
#                       XSA, so PS changes made in Vivado flow through into the
#                       Yocto build automatically.
#   validated-machine - legacy path: pin a pre-validated AMD MACHINE and convey
#                       PL hardware via a hand-curated system-user.dtsi overlay.
# List the targets that use the gen-machineconf flow here; everything else
# defaults to validated-machine.
GEN_MACHINECONF_TARGETS := zcu104
ifneq ($(filter $(TARGET),$(GEN_MACHINECONF_TARGETS)),)
	FLOW = gen-machineconf
else
	FLOW = validated-machine
endif

# Vivado paths (XSA is the hardware handoff from the Vivado project).
# The boot artifact differs per architecture:
#   - zynq / zynqMP: .bit (PL bitstream, embedded into BOOT.BIN via xilinx-bootbin)
#   - versal: .pdi   (PDI replaces the AMD reference base PDI on Versal)
VIV_DIR = $(YOCTO_ROOT)/../Vivado
VIV_PRJ_DIR = $(VIV_DIR)/$(TARGET)
VIV_XSA = $(VIV_PRJ_DIR)/$(BD_NAME)_wrapper.xsa
VIV_BIT = $(VIV_PRJ_DIR)/$(TARGET).runs/impl_1/$(BD_NAME)_wrapper.bit
VIV_PDI = $(VIV_PRJ_DIR)/$(TARGET).runs/impl_1/$(BD_NAME)_wrapper.pdi

# yocto paths and files
YOCTO_DIR = $(YOCTO_ROOT)/$(TARGET)
YOCTO_REPO_DIR = $(YOCTO_DIR)/.repo
YOCTO_SOURCES = $(YOCTO_DIR)/sources
YOCTO_SETUP = $(YOCTO_DIR)/edf-init-build-env
YOCTO_BUILD = $(YOCTO_DIR)/build
YOCTO_BUILD_CONF = $(YOCTO_BUILD)/conf
YOCTO_HW_DIR = $(YOCTO_DIR)/hw
YOCTO_HW_XSA = $(YOCTO_HW_DIR)/$(BD_NAME)_wrapper.xsa
YOCTO_MACHINE_CONF = $(YOCTO_BUILD_CONF)/multiconfig/$(TARGET).conf
YOCTO_CFG_DONE = $(YOCTO_DIR)/configdone.txt

YOCTO_IMG_DIR = $(YOCTO_DIR)/images/linux
YOCTO_BOOT_BIN = $(YOCTO_IMG_DIR)/BOOT.BIN
YOCTO_BOOT_SCR = $(YOCTO_IMG_DIR)/boot.scr
YOCTO_IMAGE = $(YOCTO_IMG_DIR)/Image
YOCTO_ROOTFS = $(YOCTO_IMG_DIR)/rootfs.tar.gz
YOCTO_WIC = $(YOCTO_IMG_DIR)/rootfs.wic.xz

YOCTO_OFFLINE = $(YOCTO_ROOT)/offline.txt
YOCTO_LOCK = $(YOCTO_ROOT)/.$(TARGET).lock

BSP_DIR = $(YOCTO_ROOT)/bsp/$(TARGET_BOARD)

# Macros to read the per-target fields
define get_template_name
$(word 1,$($(1)_target))
endef

# Offline sstate-cache (optional)
SSTATE_PATH ?= $(shell test -e $(YOCTO_OFFLINE) && head -n 1 $(YOCTO_OFFLINE))

ifeq ($(call get_template_name,$(TARGET)), zynqMP)
	SSTATE_ARCH = aarch64
	VIV_BOOTFILE = $(VIV_BIT)
else ifeq ($(call get_template_name,$(TARGET)), versal)
	SSTATE_ARCH = aarch64
	VIV_BOOTFILE = $(VIV_PDI)
else ifeq ($(call get_template_name,$(TARGET)), zynq)
	SSTATE_ARCH = arm
	VIV_BOOTFILE = $(VIV_BIT)
else ifeq ($(call get_template_name,$(TARGET)), microblaze)
	SSTATE_ARCH = microblaze
	VIV_BOOTFILE = $(VIV_BIT)
endif

# Final build products produced by bitbake (deployed into images/linux/ by package-output.sh).
# EDF produces a raw `Image` (not a u-boot-wrapped image.ub) and a `rootfs.wic.xz`
# SD-card image; `scripts/copy_to_sd.sh -yocto` flashes the wic, so include it here.
BUILD_PRODUCTS = $(YOCTO_BOOT_BIN) $(YOCTO_IMAGE) $(YOCTO_ROOTFS) $(YOCTO_WIC)

.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make yocto TARGET=<val> JOBS=<val>'
	@echo '    Build the Yocto Linux image for the specified target.'
	@echo ''
	@echo '  make all JOBS=<val>'
	@echo '    Build the Yocto Linux image for all supported targets.'
	@echo ''
	@echo '  make clean TARGET=<val>'
	@echo '    Delete the per-target Yocto workspace.'
	@echo ''
	@echo '  make clean_all'
	@echo '    Delete the Yocto workspaces of all targets.'
	@echo ''
	@echo '  make status TARGET=<val>'
	@echo '    Print the build status of the specified target.'
	@echo ''
	@echo '  make status_all'
	@echo '    Print the build status of all targets.'
	@echo ''
	@echo 'Parameters:'
	@echo ''
	@echo '  TARGET: Name of the target design, must be one of the following:'
	@$(foreach targ,$(TARGET_LIST),echo "    - $(targ)";)
	@echo ''
	@echo '  JOBS: Optional param to set number of synthesis jobs (default 8)'
	@echo ''
	@echo 'Notes:'
	@echo ''
	@echo '  - First build for a target runs `repo sync` (~5 GB of git history)'
	@echo '    and bitbake (hours without sstate, ~30 min with a local mirror).'
	@echo '  - To accelerate, place the absolute path to a directory containing'
	@echo '    an extracted aarch64 sstate-cache in $(YOCTO_OFFLINE).'
	@echo ''
	@echo 'Example usage:'
	@echo '  make yocto TARGET=$(word 1,$(TARGET_LIST))'
	@echo ''

.PHONY: yocto
yocto: check_target
	@if [ -f $(YOCTO_LOCK) ]; then \
		echo "$(TARGET) is locked. Skipping..."; \
	else \
		touch $(YOCTO_LOCK); \
		$(MAKE) --no-print-directory yocto_locked TARGET=$(TARGET) JOBS=$(JOBS); \
		rm -f $(YOCTO_LOCK); \
	fi

yocto_locked: package

package: $(BUILD_PRODUCTS)
$(BUILD_PRODUCTS): build
	@echo 'Gathering Yocto output products for $(TARGET)'
	$(YOCTO_ROOT)/scripts/package-output.sh "$(YOCTO_DIR)" "$(YOCTO_IMG_DIR)"

.PHONY: build
build: $(YOCTO_CFG_DONE)
	@echo 'Running bitbake $(YOCTO_IMAGE_RECIPE) for $(TARGET)'
	$(YOCTO_ROOT)/scripts/build-image.sh \
		"$(YOCTO_DIR)" \
		"$(YOCTO_IMAGE_RECIPE)" \
		"$(JOBS)"

$(YOCTO_CFG_DONE): $(YOCTO_HW_XSA) $(BSP_DIR)/conf/local.conf.append | $(YOCTO_SETUP)
	@echo 'Configuring Yocto build for $(TARGET)'
	$(YOCTO_ROOT)/scripts/configure-build.sh \
		"$(YOCTO_DIR)" \
		"$(TARGET)" \
		"$(BSP_DIR)" \
		"$(YOCTO_HW_XSA)" \
		"$(SSTATE_PATH)" \
		"$(SSTATE_ARCH)" \
		"$(VIV_BOOTFILE)" \
		"$(call get_template_name,$(TARGET))" \
		"$(FLOW)"
	touch $@

$(YOCTO_HW_XSA): $(VIV_XSA) | $(YOCTO_SETUP)
	mkdir -p $(YOCTO_HW_DIR)
	cp -f $(VIV_XSA) $(YOCTO_HW_XSA)

$(YOCTO_SETUP):
	@echo 'Initializing Yocto manifest workspace for $(TARGET)'
	$(YOCTO_ROOT)/scripts/init-workspace.sh \
		"$(YOCTO_DIR)" \
		"$(YOCTO_MANIFEST_URL)" \
		"$(YOCTO_MANIFEST_BRANCH)" \
		"$(YOCTO_MANIFEST_FILE)"

$(VIV_XSA):
	$(MAKE) -C $(VIV_DIR) xsa TARGET=$(TARGET) JOBS=$(JOBS)

.PHONY: all
all:
	@{ \
	for targ in $(TARGET_LIST); do \
		$(MAKE) --no-print-directory yocto TARGET=$${targ} JOBS=$(JOBS); \
	done; \
	}

.PHONY: clean
clean: check_target
	$(RM) $(YOCTO_DIR)

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
			printf 'Target %-20s: **NOT BUILT**\n' "$(TARGET)"; \
			all_built=false; \
			break; \
		fi; \
	done; \
	if $$all_built; then \
		printf 'Target %-20s: BUILT\n' "$(TARGET)"; \
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
