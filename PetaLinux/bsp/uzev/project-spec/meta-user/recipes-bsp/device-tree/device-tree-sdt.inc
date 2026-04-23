SRC_URI:append = " file://system-conf.dtsi"
EXTRA_DT_INCLUDE_FILES:append:linux = " system-user.dtsi"
EXTRA_DT_INCLUDE_FILES:append:linux-gnueabi = " system-user.dtsi"
