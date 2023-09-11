DESCRIPTION = "Custom / Misc files for Ultra96-V2"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

#FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
	    file://wpa_supplicant.conf \
	    file://wifi.sh \
	    file://bt.sh \
" 


do_install() {
	install -d ${D}/home/root/
	install -m 755 ${WORKDIR}/wpa_supplicant.conf ${D}/home/root/
	install -m 755 ${WORKDIR}/wifi.sh ${D}/home/root/
	install -m 755 ${WORKDIR}/bt.sh ${D}/home/root/
}

FILES:${PN} = " \
		/home/root/wpa_supplicant.conf \
		/home/root/wifi.sh \
		/home/root/bt.sh \
"
