FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
LIC_FILES_CHKSUM = "file://LICENSE.md;md5=a768baea9d204ad586e989c92a2afb31"

SRC_URI = "git://github.com/Avnet/BSP-rootfs-sources.git;protocol=https;branch=${SRCBRANCH};subpath=${SUBPATH} \
       file://ultra96-startup-page.sh \
       file://connman_settings \
       file://ultra96-startup-page.service \
       file://ultra96-startup-commands.sh \
       "

RDEPENDS:${PN}:remove = "\
    chromium-x11 \
"

RDEPENDS:${PN}:append = "\
     connman connman-client connman-tools \
"

SRCREV = "${AUTOREV}"

SRCBRANCH ?= "master"
SUBPATH = "ultra96-startup-pages"
S = "${WORKDIR}/${SUBPATH}"


do_install () {
    install -d ${D}${datadir}/ultra96-startup-pages
    rsync -r --exclude=".*" ${S}/* ${D}${datadir}/ultra96-startup-pages

    install -d ${D}/var/lib/connman
    install -m 0755 ${WORKDIR}/connman_settings ${D}/var/lib/connman/settings

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/ultra96-startup-commands.sh ${D}${bindir}
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/ultra96-startup-page.service ${D}${systemd_system_unitdir}

    if ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'true', 'false', d)}; then
        install -d ${D}${sysconfdir}/init.d/
        install -m 0755 ${WORKDIR}/ultra96-startup-page.sh ${D}${sysconfdir}/init.d/ultra96-startup-page.sh
    fi

}
