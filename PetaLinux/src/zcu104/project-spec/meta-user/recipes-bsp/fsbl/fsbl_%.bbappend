# Patch for FSBL
SRC_URI_append = " \
        file://zcu104_vadj_fsbl.patch \
        "
  
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
  
# Note: This is not required if you are using Yocto
EXTERNALXSCTSRC = ""
EXTERNALXSCTSRC_BUILD = ""
