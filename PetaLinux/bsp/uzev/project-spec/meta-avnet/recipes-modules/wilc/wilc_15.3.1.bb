SUMMARY = "Recipe for building an external wilc Linux kernel module"
SECTION = "PETALINUX/modules"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

inherit module

COMPATIBLE_MACHINE = "u96v2-sbc"

SRC_URI = "git://github.com/linux4wilc/driver.git;protocol=git;branch=${BRANCH} \
           file://0001-ultra96-modifications.patch \
           "

# Tag: wilc_linux_15_3_1
SRCREV = "20ab626503feb4850632337b97128f1efd73ba80"
BRANCH = "master"

DEPENDS += "virtual/kernel"

S = "${WORKDIR}/git/wilc"

EXTRA_OEMAKE = 'CONFIG_WILC=y \
		WLAN_VENDOR_MCHP=y \
		CONFIG_WILC_SDIO=m \
		CONFIG_WILC_SPI=n \
		CONFIG_WILC1000_HW_OOB_INTR=n \
		KERNEL_SRC="${STAGING_KERNEL_DIR}" \
		O=${STAGING_KERNEL_BUILDDIR}'

