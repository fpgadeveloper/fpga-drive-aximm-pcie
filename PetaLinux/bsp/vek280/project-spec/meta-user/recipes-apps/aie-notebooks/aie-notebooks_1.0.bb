DESCRIPTION = "Jupyter notebooks for AI Engine in Versal devices"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b85283c5f7bb73452c9477588361c40e"

inherit jupyter-examples

SRC_URI = "file://LICENSE				\
           file://README				\
           file://aie-matrix-multiplication.ipynb	\
           file://images/data_movement.png		\
           file://images/build_flow.png			\
           file://images/runtime.png			\
           file://images/data_movement.png		\
           "

COMPATIBLE_MACHINE = "^$"
COMPATIBLE_MACHINE:versal-ai-core = "versal-ai-core"
COMPATIBLE_MACHINE:versal-ai-edge = "${SOC_VARIANT_ARCH}"

RDEPENDS_${PN} = "packagegroup-petalinux-jupyter	\
                  aie-oob				\
                  "

do_install() {
    install -d ${D}/${JUPYTER_DIR}/aie-notebooks
    install -d ${D}/${JUPYTER_DIR}/aie-notebooks/images

    install -m 0644 ${S}/README ${D}/${JUPYTER_DIR}/aie-notebooks
    install -m 0755 ${S}/*.ipynb ${D}/${JUPYTER_DIR}/aie-notebooks
    install -m 0755 ${S}/images/*.png ${D}/${JUPYTER_DIR}/aie-notebooks/images
}

PACKAGE_ARCH:versal-ai-core = "${SOC_VARIANT_ARCH}"
PACKAGE_ARCH:versal-ai-edge = "${SOC_VARIANT_ARCH}"
