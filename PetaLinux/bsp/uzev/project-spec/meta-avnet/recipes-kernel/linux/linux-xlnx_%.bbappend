FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://bsp.cfg \
            file://user.cfg \
            file://vitis_kconfig.cfg \
            file://0001-hwmon-pmbus-Add-Infineon-IR38060-62-63-driver.patch \
            "

SRC_URI:append:u96v2-sbc = " file://fix_u96v2_pwrseq_simple.patch \
                           "

#SRC_URI:append:mz = " file://0001-irqchip-irq-xilinx-intc-use-version-from-4.19.patch \
#                     "

SRC_URI:append:uz7ev-evcc-nvme = " \
                file://nvme.cfg \
"
