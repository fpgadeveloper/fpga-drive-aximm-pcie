do_configure:append () {
	hsmoutf="${WORKDIR}/offsets"
	touch ${hsmoutf}
	ipinfof="${TOPDIR}/misc/config/data/ipinfo.yaml"
	xsct -sdx -nodisp "${PETALINUX}/etc/hsm/scripts/petalinux_hsm.tcl" \
		"get_flash_width_parts" "${SYSCONFIG_PATH}/config" "${ipinfof}" \
		"${XSCTH_HDF}" "${hsmoutf}"
}

do_compile:prepend () {
	boot_offset=$(egrep -e "^boot=" "${hsmoutf}" | cut -d "=" -f 2 | cut -d " " -f 1)
}
