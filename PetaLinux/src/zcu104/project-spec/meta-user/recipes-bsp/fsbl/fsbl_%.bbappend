# Patch for FSBL
SRC_URI_append = " \
        file://zcu104_vadj_fsbl.patch \
        "
  
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
  
#Add debug for FSBL(optional)
XSCTH_BUILD_DEBUG = "1"
  
#Enable appropriate FSBL debug flags
YAML_COMPILER_FLAGS_append = " -DXPS_BOARD_ZCU102"
  
# Note: This is not required if you are using Yocto
EXTERNALXSCTSRC = ""
EXTERNALXSCTSRC_BUILD = ""
