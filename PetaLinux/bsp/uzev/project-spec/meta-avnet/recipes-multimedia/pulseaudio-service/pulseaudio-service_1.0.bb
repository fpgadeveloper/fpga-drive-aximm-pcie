DESCRIPTION = "Pulseaudio systemd service"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd useradd

DEPENDS = "pulseaudio"

SRC_URI += "\
    file://pulseaudio.service \
    "

SYSTEMD_SERVICE:${PN} = "pulseaudio.service"

FILES:${PN} = " \
    /etc/systemd/system/pulseaudio.service \
"

USERADD_PACKAGES = "pulseaudio-service"
GROUPMEMS_PARAM:pulseaudio-service = " --add root --group audio"

do_install:append() {
    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}/etc/systemd/system
        install -m 0644 ${WORKDIR}/pulseaudio.service ${D}/etc/systemd/system/pulseaudio.service
    fi

}
