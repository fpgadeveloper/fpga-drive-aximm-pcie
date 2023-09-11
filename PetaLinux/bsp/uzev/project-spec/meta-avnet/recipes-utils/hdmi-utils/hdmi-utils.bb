DESCRIPTION = "Util scripts for hdmi"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

COMPATIBLE_MACHINE = "uz7ev-evcc-hdmi|uz7ev-evcc-hdmi-v"

FF = "files"

HDMI_FILES = " \
    file://hdmi_passthrough.sh;subdir=${FF} \
"

VCU_FILES = " \
    file://file_to_vcu_to_hdmi.sh;subdir=${FF} \
    file://hdmi_to_vcu_to_file.sh;subdir=${FF} \
    file://hdmi_to_vcu_to_hdmi.sh;subdir=${FF} \
"

SRC_URI:uz7ev-evcc-hdmi = " \
    ${HDMI_FILES} \
"

SRC_URI:uz7ev-evcc-hdmi-v = " \
    ${HDMI_FILES} \
    ${VCU_FILES} \
"

do_install() {
    install -d ${D}/${ROOT_HOME}
    install -m 777 ${WORKDIR}/${FF}/* ${D}/${ROOT_HOME}
}

FILES:${PN} = "${ROOT_HOME}/*"
