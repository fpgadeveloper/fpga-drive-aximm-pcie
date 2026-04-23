# ZCU104 FSBL VADJ patch.
#
# NOTE: 2025.2's xlnx-embeddedsw.bbclass schedules do_copy_shared_src AFTER
# do_patch (do_patch runs on an empty workdir). That means SRC_URI-attached
# .patch files can't be applied the normal way. We stage the patch with
# apply=no and run it manually in a new shell task inserted between
# do_copy_shared_src and do_configure.

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://zcu104_vadj_fsbl.patch;apply=no"

do_apply_vadj_patch() {
    cd ${S} && patch -p1 < ${WORKDIR}/zcu104_vadj_fsbl.patch
}
addtask apply_vadj_patch after do_copy_shared_src before do_configure
