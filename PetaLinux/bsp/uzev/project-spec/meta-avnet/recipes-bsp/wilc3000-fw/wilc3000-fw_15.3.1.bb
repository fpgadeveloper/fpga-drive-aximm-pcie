HOMEPAGE = "https://github.com/linux4wilc/firmware"
DESCRIPTION = "Firmware files for use with Microchip wilc3000"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = "file://LICENSE.wilc_fw;md5=89ed0ff0e98ce1c58747e9a39183cc9f"

SRC_URI = "git://github.com/linux4wilc/firmware.git;protocol=git;branch=${BRANCH}"

# Tag: wilc_linux_15_3_1
SRCREV = "990275ca7f6e3debc58aaac77918176e55f23a96"
BRANCH = "master"

S = "${WORKDIR}/git"

# Depends on Wilc driver https://github.com/Avnet/u96v2-wilc-driver
DEPENDS += "wilc"

do_install() {
    install -d ${D}${base_libdir}/firmware/mchp
    install -m 0755 ${S}/wilc* ${D}${base_libdir}/firmware/mchp
}

FILES:${PN} = "${base_libdir}/firmware/mchp/*"
