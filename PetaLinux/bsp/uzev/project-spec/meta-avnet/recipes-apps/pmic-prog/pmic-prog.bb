#
# This is the pmic-prog application recipe
#
#

SUMMARY = "pmic-prog application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "i2c-tools"

COMPATIBLE_MACHINE = "uz|u96v2-sbc"

SRC_URI = "git://github.com/Avnet/BSP-rootfs-sources.git;protocol=https;branch=${SRCBRANCH};subpath=${SUBPATH};"

SRC_URI:append:uz = " file://pmic-configs/"
SRC_URI:append:u96v2-sbc = " file://pmic-configs/"

SRCREV = "${AUTOREV}"

SRCBRANCH ?= "master"
SUBPATH = "pmic-prog"
S = "${WORKDIR}/${SUBPATH}"

inherit pkgconfig cmake

FILES:${PN} += "${ROOT_HOME}/${SUBPATH}/*"

do_install() {
        install -d ${D}${ROOT_HOME}/${SUBPATH}
        install -m 0755 ${B}/pmic_prog ${D}${ROOT_HOME}/${SUBPATH}/
}

do_install:append:uz() {
        cp -r ${WORKDIR}/pmic-configs ${D}${ROOT_HOME}/${SUBPATH}/
}

do_install:append:u96v2-sbc() {
        cp -r ${WORKDIR}/pmic-configs ${D}${ROOT_HOME}/${SUBPATH}/
}

