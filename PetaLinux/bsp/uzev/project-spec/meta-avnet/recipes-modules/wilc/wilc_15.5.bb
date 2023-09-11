SUMMARY = "Recipe for building an external wilc Linux kernel module"
SECTION = "PETALINUX/modules"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

inherit module

COMPATIBLE_MACHINE = "u96v2-sbc"

SRC_URI = "git://github.com/linux4sam/linux-at91.git;protocol=git;branch=${BRANCH};subpath=drivers/net/wireless/microchip/wilc1000 \
           file://0001-ultra96-modifications-15.5.patch \
           "

# Tag: wilc_linux_15_3_1
SRCREV = "f828d684531f354f0ca6fcd2cdf12c8251410cba"
BRANCH = "linux-5.10-at91"

DEPENDS += "virtual/kernel"

S = "${WORKDIR}/wilc1000"

EXTRA_OEMAKE = 'CONFIG_WILC=y \
		WLAN_VENDOR_MCHP=y \
		CONFIG_WILC_SDIO=m \
		CONFIG_WILC_SPI=n \
		CONFIG_WILC1000_HW_OOB_INTR=n \
		KERNEL_SRC="${STAGING_KERNEL_DIR}" \
		O=${STAGING_KERNEL_BUILDDIR}'

