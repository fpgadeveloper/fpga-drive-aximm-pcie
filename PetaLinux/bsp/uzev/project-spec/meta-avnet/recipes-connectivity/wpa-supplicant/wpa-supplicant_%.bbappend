FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

do_install:prepend () {
    sed -i 's/^\(Exec=.*\)$/#\1/g' ${S}/wpa_supplicant/dbus/fi.w1.wpa_supplicant1.service
}
