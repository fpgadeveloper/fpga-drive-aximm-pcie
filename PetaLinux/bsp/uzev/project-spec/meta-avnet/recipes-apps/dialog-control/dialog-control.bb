#
# This file is the dialog-control recipe.
#

SUMMARY = "Simple dialog-control application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://dialog-control.cpp \
           file://Makefile \
		  "

S = "${WORKDIR}"

DEPENDS:append = "gpio-utils"

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}${bindir}
	     install -m 0755 dialog-control ${D}${bindir}
}
