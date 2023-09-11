SUMMARY = "GTK GUI for ConnMan"
LICENSE = "GPLv2.0+"
SECTION = "network"

LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

DEPENDS = "glib-2.0 gtk+3 intltool-native"

inherit meson pkgconfig gsettings

SRCREV = "b72c6ab3bb19c07325c8e659902b046daa23c506"
SRC_URI = "git://github.com/jgke/connman-gtk.git;protocol=https \
           file://0001-data-modify-desktop-file-for-matchbox.patch \
           "

S = "${WORKDIR}/git"

EXTRA_OEMESON += " \
"

FILES:${PN} += " \
    ${datadir}/ \
"
