#
# This file is the sds-lib recipe.
#

SUMMARY = "sds-lib"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://libsds_lib.so \
	   file://libsds_lib_dbg.so \
	"

S = "${WORKDIR}"

do_install() {
	     install -d ${D}/${libdir}
	     install -m 0755 ${S}/libsds_lib.so ${D}/${libdir}
	     install -m 0755 ${S}/libsds_lib_dbg.so ${D}/${libdir}
}

FILES:${PN} += "${libdir}"
FILES_SOLIBSDEV = ""
