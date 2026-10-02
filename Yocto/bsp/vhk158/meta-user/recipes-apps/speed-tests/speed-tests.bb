#
# This file is the speed-tests recipe.
#

SUMMARY = "Scripts for Opsero NVMe speed tests"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://single_read_test.sh \
	   file://single_write_test.sh \
	   file://dual_read_test.sh \
	   file://dual_write_test.sh \
		  "

S = "${WORKDIR}"

RDEPENDS:${PN} += "bash"

do_install() {
        install -d ${D}${bindir}
        install -m 0755 ${WORKDIR}/single_read_test.sh ${D}${bindir}/
        install -m 0755 ${WORKDIR}/single_write_test.sh ${D}${bindir}/
        install -m 0755 ${WORKDIR}/dual_read_test.sh ${D}${bindir}/
        install -m 0755 ${WORKDIR}/dual_write_test.sh ${D}${bindir}/
}
