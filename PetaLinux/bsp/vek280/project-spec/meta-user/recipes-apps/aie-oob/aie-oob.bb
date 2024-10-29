#
# This file is the added recipe.
#

SUMMARY = "aie-oob application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://aie-matrix-multiplication \
           file://aie-matrix-multiplication.xclbin \
        "
INSANE_SKIP:${PN} += " arch file-rdeps"

S = "${WORKDIR}"

do_install() {
	install -d ${D}/${bindir}
	install -m 0755 ${S}/aie-matrix-multiplication ${D}/${bindir}/
	install -m 0755 ${S}/aie-matrix-multiplication.xclbin ${D}/${bindir}/
}
