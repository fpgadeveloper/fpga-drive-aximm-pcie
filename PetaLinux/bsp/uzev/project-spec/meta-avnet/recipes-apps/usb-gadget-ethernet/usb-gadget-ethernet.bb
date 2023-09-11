#
# This file is the usb-gadget-ethernet recipe.
#

SUMMARY = "A usb-gadget-ethernet interface setup script"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://usb_gadget_ethernet.sh \
		  "

S = "${WORKDIR}"

do_install() {
	     install -d ${D}/home/root
	     install -m 0755 usb_gadget_ethernet.sh ${D}/home/root
}

FILES:${PN} += "/home/root/usb_gadget_ethernet.sh \
               "
