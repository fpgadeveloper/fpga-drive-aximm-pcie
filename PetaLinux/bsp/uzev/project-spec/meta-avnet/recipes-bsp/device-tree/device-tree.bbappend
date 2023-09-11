FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Remove avnet-ultra96-rev1 dependency
YAML_DT_BOARD_FLAGS:u96v2-sbc ?= "{BOARD template}"

SRC_URI:append = "\
	file://system-bsp.dtsi \
"

SRC_URI:append:u96v2-sbc = "\
	file://openamp.dtsi \
"

SRC_URI:append:uz7ev-evcc-hdmi = "\
	file://hdmi.dtsi \
"

# For Avnet BSP only
do_configure:append () {
	if [ -e ${WORKDIR}/system-bsp.dtsi ]; then
		cp ${WORKDIR}/system-bsp.dtsi ${DT_FILES_PATH}/system-bsp.dtsi
		echo '#include "system-bsp.dtsi"' >> ${DT_FILES_PATH}/${BASE_DTS}.dts
	fi
}

# For Ultra96-SBC BSP only
do_configure:append:u96v2-sbc () {
	if [ -e ${WORKDIR}/openamp.dtsi ]; then
		cp ${WORKDIR}/openamp.dtsi ${DT_FILES_PATH}/openamp.dtsi
		echo '#include "openamp.dtsi"' >> ${DT_FILES_PATH}/${BASE_DTS}.dts
	fi
}

# For uz7ev-evcc-hdmi BSP only
do_configure:append:uz7ev-evcc-hdmi () {
	if [ -e ${WORKDIR}/hdmi.dtsi ]; then
		cp ${WORKDIR}/hdmi.dtsi ${DT_FILES_PATH}/hdmi.dtsi
		echo '#include "hdmi.dtsi"' >> ${DT_FILES_PATH}/${BASE_DTS}.dts
	fi
}
