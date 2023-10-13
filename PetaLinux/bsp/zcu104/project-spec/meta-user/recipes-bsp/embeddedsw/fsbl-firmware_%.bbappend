# Patch for FSBL
SRC_URI:append = " \
        file://zcu104_vadj_fsbl.patch \
        "
  
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

