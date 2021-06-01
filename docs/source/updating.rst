=====================
Updating the projects
=====================

This section contains instructions for updating the reference designs. It is intended as a guide
for anyone wanting to attempt updating the designs for a tools release that we do not yet support.
Note that the update process is not always straight-forward and sometimes requires dealing with
new issues or significant changes to the functionality of the tools and/or specific IP. Unfortunately, 
we cannot always provide support if you have trouble updating the designs.

Vivado projects
===============

1. Download and install the Vivado release that you intend to use.
2. If you are using one of the following boards, you will have to download and install the latest 
   board files for that target platform. Other boards are already built into Vivado and require no
   extra installation.

   * PicoZed board files can be downloaded `here <https://github.com/Avnet/bdf>`_
   * UltraZed EV board files can be downloaded `here <https://github.com/Avnet/bdf>`_
   
3. In a text editor, open the ``Vivado/build-<target>.bat`` file for
   the design that you wish to update, and perform the following changes:
   
   * Update the tools version number to the one you are using (eg. 2020.2)
   
4. In a text editor, open the ``Vivado/build-<target>.tcl`` file for
   the design that you wish to update, and perform the following changes:
   
   * Update the ``version_required`` variable value to the tools version number 
     that you are using.
   * Update the year in all references to ``Vivado Synthesis <year>`` to the 
     tools version number that you are using. For example, if you are using tools
     version 2020.2, then the ``<year>`` should be 2020.
   * Update the year in all references to ``Vivado Implementation <year>`` to the 
     tools version number that you are using. For example, if you are using tools
     version 2020.2, then the ``<year>`` should be 2020.
   * If the version of the board files for your target platform has changed, update 
     the ``board_part`` parameter value to the new version.

After following the above steps, you can now run the build script. If there were no significant changes
to the tools and/or IP, the build script should succeed and you will be able to open and generate a 
bitstream for the Vivado project.

PetaLinux
=========

The main procedure for updating the PetaLinux project is to update the BSP for the target platform.
The BSP files for each supported target platform are contained in the ``PetaLinux/src`` directory.
For example, the BSP files for the KC705 are located in ``PetaLinux/src/kc705``.

#. Download and install the PetaLinux release that you intend to use.
#. Download and install the BSP for the target platform for the release that you intend to use.

   * For KC705, KCU105, ZC706, ZCU104, ZCU106 and ZCU111, download the BSP from the 
     `PetaLinux download page <https://www.xilinx.com/petalinux>`_
   * For VC707 and VC709, download the BSP for the **KC705** from the 
     `PetaLinux download page <https://www.xilinx.com/petalinux>`_
   * For PicoZed, download the BSP for the **ZedBoard** from the 
     `PetaLinux download page <https://www.xilinx.com/petalinux>`_
   * UltraZed EV, download the BSP for the **ZCU102** from the 
     `PetaLinux download page <https://www.xilinx.com/petalinux>`_

#. Update the BSP files for the target platform in the ``PetaLinux/src/<platform>`` directory. 
   These are the specific directories to update:
   
   * ``<platform>/project-spec/configs/*``
   * ``<platform>/project-spec/meta-user/*``
   
   The simple way to update the files is to delete those in the repository and copy in those from
   the BSP that you just downloaded.
   
#. Apply the required modifications to the updated BSP files. The modifications are described for each
   target platform in the following sections.
   
Change project name
-------------------

This BSP modification applies to all target platforms.

1. Append the following lines to ``project-spec/configs/config``:

.. code-block:: 
   
  # Set project name
  CONFIG_SUBSYSTEM_HOSTNAME="fpgadrive"
  CONFIG_SUBSYSTEM_PRODUCT="fpgadrive"
   
Note that this will set the project name to "fpgadrive" but you can use a more descriptive name, for example
one that includes the target platform name and the tools version.

Add tools to root filesystem
----------------------------

This BSP modification applies to all target platforms.

1. Append the following lines to ``project-spec/configs/rootfs_config``:

.. code-block::

   # Tools to disable (to reduce size)
   
   CONFIG_canutils=n
   CONFIG_openssh-sftp-server=n
   CONFIG_packagegroup-core-ssh-dropbear=n

   # Tools for FPGA Drive FMC
   
   CONFIG_e2fsprogs=y
   CONFIG_e2fsprogs-mke2fs=y
   CONFIG_e2fsprogs-badblocks=y
   CONFIG_mtd-utils=y
   CONFIG_util-linux=y
   CONFIG_util-linux-mount=y
   CONFIG_util-linux-mkfs=y
   CONFIG_util-linux-blkid=y
   CONFIG_util-linux-fdisk=y
   CONFIG_pciutils=y
   CONFIG_bridge-utils=y

2. Append the following lines to ``project-spec/meta-user/conf/user-rootfsconfig``:

.. code-block::

   CONFIG_e2fsprogs
   CONFIG_e2fsprogs-mke2fs
   CONFIG_e2fsprogs-badblocks
   CONFIG_mtd-utils
   CONFIG_util-linux
   CONFIG_util-linux-mount
   CONFIG_util-linux-mkfs
   CONFIG_util-linux-blkid
   CONFIG_util-linux-fdisk
   CONFIG_pciutils
   CONFIG_bridge-utils

Disable Use Virtual Terminal
----------------------------

This config file is required to prevent an error message and is required on all designs.

1. Create file ``project-spec/meta-user/recipes-core/sysvinit/sysvinit-inittab_%.bbappend`` with the following content:

.. code-block:: 
   
   # https://forums.xilinx.com/t5/Embedded-Linux/Why-does-Petalinux-2017-3-start-sbin-getty-38400-tty1/m-p/816074/highlight/true#M23274
   # Added to stop this error message: INIT: Id "1" respawning too fast: disabled for 5 minutes
   
   USE_VT = "0"

Mods for all Microblaze designs
-------------------------------

The following modifications apply to all the Microblaze based designs (KC705, KCU105, VC707, VC709).

1. Append the following lines to file ``project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg``:

.. code-block::

   # Kernel config specific to Microblaze processor designs
   
   CONFIG_GENERIC_MSI_IRQ=y
   CONFIG_PCI_MSI=y
   CONFIG_PCI_REALLOC_ENABLE_AUTO=y
   CONFIG_PCIE_XILINX=y
   CONFIG_NVME_CORE=y
   CONFIG_BLK_DEV_NVME=y
   
   # All the axi_pcie and axi_pcie3 designs using Microblaze need these kernel options to move 
   # the Kernel start address down to make room for more VMALLOC space, which is needed for 
   # the CTL0 interfaces.
   # With one axi_pcie/axi_pcie3 IP in the design, we need 256MB more VMALLOC space.
   # With two axi_pcie/axi_pcie3 IPs in the design, we need 512MB more VMALLOC space.
   # To keep the project simple, we add 512MB more VMALLOC space to ALL Microblaze designs.
   # https://forums.xilinx.com/t5/Embedded-Linux/How-to-increase-size-of-vmalloc-for-PetaLinux-on-MicroBlaze/m-p/881943
   # Kernel start address moved to 0xA0000000 from 0xC0000000
   
   CONFIG_ADVANCED_OPTIONS=y
   CONFIG_KERNEL_START_BOOL=y
   CONFIG_KERNEL_START=0xA0000000

Mods for all Zynq-7000 designs
-------------------------------

The following modifications apply to all the Zynq-7000 based designs (PicoZed, ZC706).

1. Append the following lines to ``project-spec/configs/rootfs_config``:

.. code-block::

   # Add coreutils for full version of dd
   
   CONFIG_coreutils=y

2. Append the following lines to file ``project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg``:

.. code-block::

   # Kernel config specific to Zynq-7000 designs
   
   CONFIG_NVME_CORE=y
   CONFIG_BLK_DEV_NVME=y
   
   # All the axi_pcie designs need these kernel options to move the Kernel start address
   # down to make room for more VMALLOC space, which is needed for the CTL interface.
   # More info here (although for the Microblaze, this also applies to Zynq designs):
   # https://forums.xilinx.com/t5/Embedded-Linux/How-to-increase-size-of-vmalloc-for-PetaLinux-on-MicroBlaze/m-p/881943
   # Kernel start address moved to 0x80000000 from 0xC0000000
   
   CONFIG_ARCH_MMAP_RND_BITS_MAX=15
   CONFIG_VMSPLIT_2G=y
   CONFIG_PAGE_OFFSET=0x80000000

Mods for all Zynq UltraScale+ designs
-------------------------------------

The following modifications apply to all the Zynq UltraScale+ based designs (UltraZed-EV, ZCU104, ZCU106, ZCU111).

1. Append the following lines to ``project-spec/configs/rootfs_config``:

.. code-block::

   # Add coreutils for full version of dd
   
   CONFIG_coreutils=y

2. Append the following lines to file ``project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg``:

.. code-block::

   # Kernel config specific to Zynq UltraScale+ designs
   
   CONFIG_PCI_REALLOC_ENABLE_AUTO=y
   CONFIG_PCIE_XDMA_PL=y
   CONFIG_NVME_CORE=y
   CONFIG_BLK_DEV_NVME=y
   CONFIG_NVME_TARGET=y

Patch for all Microblaze designs without Ethernet
-------------------------------------------------

The 2020.2 release required a patch for all Microblaze designs that did not have Ethernet (KCU105, VC707, VC709). The problem is described here:

`PetaLinux 2020.2 build failure - Microblaze without Ethernet <https://forums.xilinx.com/t5/Embedded-Linux/Petalinux-2020-2-build-failure-Microblaze-without-Ethernet/td-p/1181581>`_

This issue may be fixed in future releases of PetaLinux, and thus this patch may not be necessary. If however you run
into the same issue, you will need to create an updated patch here: ``project-spec/meta-user/recipes-bsp/u-boot/files/remove-pxe.patch``
and add the following line to ``project-spec/meta-user/recipes-bsp/u-boot/u-boot-xlnx_%.bbappend``.

.. code-block::

   SRC_URI += "file://remove-pxe.patch"

Mods for KC705
---------------

These modifications are specific to the KC705 BSP.

1. Append the following lines to ``project-spec/configs/config``:

.. code-block:: 
   
   # KC705 configs
   
   CONFIG_SUBSYSTEM_MACHINE_NAME="kc705-lite"
   
   # Increase kernel partition size
   CONFIG_SUBSYSTEM_FLASH_AXI_EMC_0_BANK0_PART3_SIZE=0xF00000

2. Append the following lines to ``project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h``.

.. code-block:: 
   
   /* BOOTCOMMAND */
   #define CONFIG_BOOTCOMMAND	"cp.b ${kernelstart} ${netstartaddr} ${kernelsize} && bootm ${netstartaddr}"
   
   /* Extra U-Boot Env settings */
   #define CONFIG_EXTRA_ENV_SETTINGS \
   	SERIAL_MULTI \ 
   	CONSOLE_ARG \ 
   	ESERIAL0 \ 
   	"nc=setenv stdout nc;setenv stdin nc;\0" \ 
   	"ethaddr=00:0a:35:00:22:01\0" \
   	"autoload=no\0" \ 
   	"sdbootdev=0\0" \ 
   	"clobstart=0x80000000\0" \ 
   	"netstart=0x80000000\0" \ 
   	"dtbnetstart=0x81e00000\0" \ 
   	"netstartaddr=0x81000000\0"  "loadaddr=0x80000000\0" \ 
   	"initrd_high=0x0\0" \ 
   	"bootsize=0x180000\0" \ 
   	"bootstart=0x60b00000\0" \ 
   	"boot_img=u-boot-s.bin\0" \ 
   	"load_boot=tftpboot ${clobstart} ${boot_img}\0" \ 
   	"update_boot=setenv img boot; setenv psize ${bootsize}; setenv installcmd \"install_boot\"; run load_boot test_img; setenv img; setenv psize; setenv installcmd\0" \ 
   	"install_boot=protect off ${bootstart} +${bootsize} && erase ${bootstart} +${bootsize} && "  "cp.b ${clobstart} ${bootstart} ${filesize}\0" \ 
   	"bootenvsize=0x20000\0" \ 
   	"bootenvstart=0x60c80000\0" \ 
   	"eraseenv=protect off ${bootenvstart} +${bootenvsize} && erase ${bootenvstart} +${bootenvsize}\0" \ 
   	"kernelsize=0xf00000\0" \ 
   	"kernelstart=0x60ca0000\0" \ 
   	"kernel_img=image.ub\0" \ 
   	"load_kernel=tftpboot ${clobstart} ${kernel_img}\0" \ 
   	"update_kernel=setenv img kernel; setenv psize ${kernelsize}; setenv installcmd \"install_kernel\"; run load_kernel test_crc; setenv img; setenv psize; setenv installcmd\0" \ 
   	"install_kernel=protect off ${kernelstart} +${kernelsize} && erase ${kernelstart} +${kernelsize} && "  "cp.b ${clobstart} ${kernelstart} ${filesize}\0" \ 
   	"cp_kernel2ram=cp.b ${kernelstart} ${netstart} ${kernelsize}\0" \ 
   	"fpgasize=0xb00000\0" \ 
   	"fpgastart=0x60000000\0" \ 
   	"fpga_img=system.bit.bin\0" \ 
   	"load_fpga=tftpboot ${clobstart} ${fpga_img}\0" \ 
   	"update_fpga=setenv img fpga; setenv psize ${fpgasize}; setenv installcmd \"install_fpga\"; run load_fpga test_img; setenv img; setenv psize; setenv installcmd\0" \ 
   	"install_fpga=protect off ${fpgastart} +${fpgasize} && erase ${fpgastart} +${fpgasize} && "  "cp.b ${clobstart} ${fpgastart} ${filesize}\0" \ 
   	"fault=echo ${img} image size is greater than allocated place - partition ${img} is NOT UPDATED\0" \ 
   	"test_crc=if imi ${clobstart}; then run test_img; else echo ${img} Bad CRC - ${img} is NOT UPDATED; fi\0" \ 
   	"test_img=setenv var \"if test ${filesize} -gt ${psize}\\; then run fault\\; else run ${installcmd}\\; fi\"; run var; setenv var\0" \ 
   	"netboot=tftpboot ${netstartaddr} ${kernel_img} && bootm\0" \ 
   	"default_bootcmd=bootcmd\0" \ 
   ""

Mods for KCU105
---------------

These modifications are specific to the KCU105 BSP.

1. Append the following lines to ``project-spec/configs/config``:

.. code-block:: 
   
   # KCU105 configs
   
   CONFIG_SUBSYSTEM_MACHINE_NAME="template"
   
   # Increase kernel partition size
   CONFIG_SUBSYSTEM_FLASH_AXI_QUAD_SPI_0_BANKLESS_PART3_SIZE=0xD00000

2. Append the following lines to ``project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h``.

.. code-block:: 
   
   /* BOOTCOMMAND */
   #define CONFIG_BOOTCOMMAND	"sf probe 0 && sf read ${netstartaddr} ${kernelstart} ${kernelsize} && bootm ${netstartaddr}"
   
   /* Extra U-Boot Env settings */
   #define CONFIG_EXTRA_ENV_SETTINGS \
   	SERIAL_MULTI \ 
   	CONSOLE_ARG \ 
   	ESERIAL0 \ 
   	"autoload=no\0" \ 
   	"sdbootdev=0\0" \ 
   	"clobstart=0x80000000\0" \ 
   	"netstart=0x80000000\0" \ 
   	"dtbnetstart=0x81e00000\0" \ 
   	"netstartaddr=0x81000000\0"  "loadaddr=0x80000000\0" \ 
   	"initrd_high=0x0\0" \ 
   	"bootsize=0x180000\0" \ 
   	"bootstart=0x1000000\0" \ 
   	"boot_img=u-boot-s.bin\0" \ 
   	"install_boot=sf probe 0 && sf erase ${bootstart} ${bootsize} && " \ 
   		"sf write ${clobstart} ${bootstart} ${filesize}\0" \ 
   	"bootenvsize=0x40000\0" \ 
   	"bootenvstart=0x1180000\0" \ 
   	"eraseenv=sf probe 0 && sf erase ${bootenvstart} ${bootenvsize}\0" \ 
   	"kernelsize=0xd00000\0" \ 
   	"kernelstart=0x11c0000\0" \ 
   	"kernel_img=image.ub\0" \ 
   	"install_kernel=sf probe 0 && sf erase ${kernelstart} ${kernelsize} && " \ 
   		"sf write ${clobstart} ${kernelstart} ${filesize}\0" \ 
   	"cp_kernel2ram=sf probe 0 && sf read ${netstartaddr} ${kernelstart} ${kernelsize}\0" \ 
   	"fpgasize=0x1000000\0" \ 
   	"fpgastart=0x0\0" \ 
   	"fpga_img=system.bit.bin\0" \ 
   	"install_fpga=sf probe 0 && sf erase ${fpgastart} ${fpgasize} && " \ 
   		"sf write ${clobstart} ${fpgastart} ${filesize}\0" \ 
   	"fault=echo ${img} image size is greater than allocated place - partition ${img} is NOT UPDATED\0" \ 
   	"test_crc=if imi ${clobstart}; then run test_img; else echo ${img} Bad CRC - ${img} is NOT UPDATED; fi\0" \ 
   	"test_img=setenv var \"if test ${filesize} -gt ${psize}\\; then run fault\\; else run ${installcmd}\\; fi\"; run var; setenv var\0" \ 
   	"default_bootcmd=bootcmd\0" \ 
   ""

3. Append the following lines to file ``project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi``:

.. code-block:: 
   
   &iic_main {
   	#address-cells = <1>;
   	#size-cells = <0>;
   	i2c-mux@75 {
   		compatible = "nxp,pca9544";
   		#address-cells = <1>;
   		#size-cells = <0>;
   		reg = <0x75>;
   		i2c@3 {
   			#address-cells = <1>;
   			#size-cells = <0>;
   			reg = <3>;
   			eeprom@54 {
   				compatible = "atmel,24c08";
   				reg = <0x54>;
   			};
   		};
   	};
   };

Mods for VC707 and VC709
------------------------

These modifications are specific to the VC707 and VC709 designs.

Xilinx does not provide PetaLinux BSPs for the VC707 and VC709 boards, so in these designs, we use the BSP
for the KC705 board with the following modifications.

1. In file ``project-spec/configs/linux-xlnx/plnx_kernel.cfg``, modify the value of ``CONFIG_XILINX_MICROBLAZE0_FAMILY``
   from ``kintex7`` to ``virtex7``.

2. Append the following lines to ``project-spec/configs/config``:

.. code-block:: 
   
   # VC707/VC709 configs
   
   CONFIG_SUBSYSTEM_MACHINE_NAME="template"
   
   # Increase kernel partition size
   CONFIG_SUBSYSTEM_FLASH_AXI_EMC_0_BANK0_PART3_SIZE=0xF00000

3. Append the following lines to ``project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h``.

.. code-block:: 
   
   /* BOOTCOMMAND */
   #define CONFIG_BOOTCOMMAND	"cp.b ${kernelstart} ${netstartaddr} ${kernelsize} && bootm ${netstartaddr}"
   
   /* Extra U-Boot Env settings */
   #define CONFIG_EXTRA_ENV_SETTINGS \
   	SERIAL_MULTI \ 
   	CONSOLE_ARG \ 
   	ESERIAL0 \ 
   	"autoload=no\0" \ 
   	"sdbootdev=0\0" \ 
   	"clobstart=0x80000000\0" \ 
   	"netstart=0x80000000\0" \ 
   	"dtbnetstart=0x81e00000\0" \ 
   	"netstartaddr=0x81000000\0"  "loadaddr=0x80000000\0" \ 
   	"initrd_high=0x0\0" \ 
   	"bootsize=0x180000\0" \ 
   	"bootstart=0x60b00000\0" \ 
   	"boot_img=u-boot-s.bin\0" \ 
   	"install_boot=protect off ${bootstart} +${bootsize} && erase ${bootstart} +${bootsize} && "  "cp.b ${clobstart} ${bootstart} ${filesize}\0" \ 
   	"bootenvsize=0x20000\0" \ 
   	"bootenvstart=0x60c80000\0" \ 
   	"eraseenv=protect off ${bootenvstart} +${bootenvsize} && erase ${bootenvstart} +${bootenvsize}\0" \ 
   	"kernelsize=0xf00000\0" \ 
   	"kernelstart=0x60ca0000\0" \ 
   	"kernel_img=image.ub\0" \ 
   	"install_kernel=protect off ${kernelstart} +${kernelsize} && erase ${kernelstart} +${kernelsize} && "  "cp.b ${clobstart} ${kernelstart} ${filesize}\0" \ 
   	"cp_kernel2ram=cp.b ${kernelstart} ${netstart} ${kernelsize}\0" \ 
   	"fpgasize=0xb00000\0" \ 
   	"fpgastart=0x60000000\0" \ 
   	"fpga_img=system.bit.bin\0" \ 
   	"install_fpga=protect off ${fpgastart} +${fpgasize} && erase ${fpgastart} +${fpgasize} && "  "cp.b ${clobstart} ${fpgastart} ${filesize}\0" \ 
   	"fault=echo ${img} image size is greater than allocated place - partition ${img} is NOT UPDATED\0" \ 
   	"test_crc=if imi ${clobstart}; then run test_img; else echo ${img} Bad CRC - ${img} is NOT UPDATED; fi\0" \ 
   	"test_img=setenv var \"if test ${filesize} -gt ${psize}\\; then run fault\\; else run ${installcmd}\\; fi\"; run var; setenv var\0" \ 
   	"default_bootcmd=bootcmd\0" \ 
   ""

4. Remove all lines from file ``project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg``. These kernel configs are specific to
   the KC705 and are not required by the VC707 or VC709 designs.

Mods for ZCU104
---------------

These modifications are specific to the ZCU104 BSP.

1. Add patch for FSBL to ``project-spec/meta-user/recipes-bsp/fsbl/``. You will have to update this
   patch for the version of PetaLinux that you are using. Refer to the existing patch files in that
   location for guidance.

Mods for ZCU106
---------------

These modifications are specific to the ZCU106 BSP.

1. Append the following lines to ``project-spec/configs/config``. The first option prevents the removal of
   the PL DTB nodes that we need in this design. The second option disables the FPGA manager.

.. code-block:: 
   
   # ZCU106 configs
   
   CONFIG_SUBSYSTEM_REMOVE_PL_DTB=n
   CONFIG_SUBSYSTEM_FPGA_MANAGER=n
   
