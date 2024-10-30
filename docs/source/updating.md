# Updating the projects

This section contains instructions for updating the reference designs. It is intended as a guide
for anyone wanting to attempt updating the designs for a tools release that we do not yet support.
Note that the update process is not always straight-forward and sometimes requires dealing with
new issues or significant changes to the functionality of the tools and/or specific IP. Unfortunately, 
we cannot always provide support if you have trouble updating the designs.

## Vivado projects

1. Download and install the Vivado release that you intend to use.
2. In a text editor, open the `Vivado/scripts/build.tcl` file and perform the following changes:
   * Update the `version_required` variable value to the tools version number 
     that you are using.
   * Update the year in all references to `Vivado Synthesis <year>` to the 
     tools version number that you are using. For example, if you are using tools
     version 2024.1, then the `<year>` should be 2024.
   * Update the year in all references to `Vivado Implementation <year>` to the 
     tools version number that you are using. For example, if you are using tools
     version 2024.1, then the `<year>` should be 2024.
3. In a text editor, open the `Vivado/scripts/xsa.tcl` file and perform the following changes:
   * Update the `version_required` variable value to the tools version number 
     that you are using.
4. **Windows users only:** In a text editor, open the `Vivado/build-vivado.bat` file and update 
   the tools version number to the one you are using (eg. 2024.1).

After completing the above, you should now be able to use the [build instructions](build_instructions) to
build the Vivado project. If there were no significant changes to the tools and/or IP, the build script 
should succeed and you will be able to open and generate a bitstream.

## PetaLinux

The main procedure for updating the PetaLinux project is to update the BSP for the target platform.
The BSP files for each supported target platform are contained in the `PetaLinux/bsp` directory.

1. Download and install the PetaLinux release that you intend to use.
2. Download and install the BSP for the target platform for the release that you intend to use.

   * For AMD Xilinx eval boards download the BSP from the [Xilinx downloads] page
   * For PicoZed and UltraZed-EV download the BSP from the [Avnet downloads] page

3. Update the BSP files for the target platform in the `PetaLinux/bsp/<platform>` directory. 
   These are the specific directories to update:
   * `<platform>/project-spec/configs/*`
   * `<platform>/project-spec/meta-user/*`   
   The simple way to update the files is to delete the `configs` and `meta-user` folders from the repository
   and copy in those folders from the more recent BSP.
4. Apply the required modifications to the updated BSP files. The modifications are described for each
   target platform in the following sections.
   
### Change project name

This BSP modification applies to all target platforms.

1. Append the following lines to `project-spec/configs/config`:

```
# Set project name
CONFIG_SUBSYSTEM_HOSTNAME="fpgadrive"
CONFIG_SUBSYSTEM_PRODUCT="fpgadrive"
```
   
Note that this will set the project name to "fpgadrive" but you can use a more descriptive name, for example
one that includes the target platform name and the tools version.

### Add tools to root filesystem

This BSP modification applies to all target platforms.

1. Append the following lines to `project-spec/configs/rootfs_config`:

```
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
```

2. Append the following lines to `project-spec/meta-user/conf/user-rootfsconfig`:

```
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
CONFIG_nvme-cli
```

### Disable Use Virtual Terminal

This config file is required to prevent an error message and is required on all designs.

1. Create file `project-spec/meta-user/recipes-core/sysvinit/sysvinit-inittab_%.bbappend` with the following content:

```
# https://forums.xilinx.com/t5/Embedded-Linux/Why-does-Petalinux-2017-3-start-sbin-getty-38400-tty1/m-p/816074/highlight/true#M23274
# Added to stop this error message: INIT: Id "1" respawning too fast: disabled for 5 minutes

USE_VT = "0"
```

### Mods for all Zynq-7000 designs

The following modifications apply to all the Zynq-7000 based designs (PicoZed, ZC706).

1. Append the following lines to `project-spec/configs/config`. These options configure the design
   to use the SD card to store the root filesystem.

```
# SD card for root filesystem

CONFIG_SUBSYSTEM_BOOTARGS_AUTO=n
CONFIG_SUBSYSTEM_USER_CMDLINE="earlycon console=ttyPS0,115200 clk_ignore_unused root=/dev/mmcblk0p2 rw rootwait cma=1536M"

CONFIG_SUBSYSTEM_ROOTFS_INITRD=n
CONFIG_SUBSYSTEM_ROOTFS_EXT4=y
CONFIG_SUBSYSTEM_SDROOT_DEV="/dev/mmcblk0p2"
CONFIG_SUBSYSTEM_RFS_FORMATS="tar.gz ext4 ext4.gz "
```

2. Append the following lines to `project-spec/configs/rootfs_config`:

```
# Add coreutils for full version of dd, and nvme-cli for NVMe tools

CONFIG_coreutils=y
CONFIG_nvme-cli=y
```

3. Append the following lines to file `project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg`:

```
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
```

### Mods for all Zynq UltraScale+ designs

The following modifications apply to all the Zynq UltraScale+ based designs (UltraZed-EV, ZCU104, ZCU106, ZCU111, ZCU208).

1. Append the following lines to `project-spec/configs/config`. These options configure the design
   to use the SD card to store the root filesystem.

```
# SD card for root filesystem

CONFIG_SUBSYSTEM_BOOTARGS_AUTO=n
CONFIG_SUBSYSTEM_USER_CMDLINE="earlycon console=ttyPS0,115200 clk_ignore_unused root=/dev/mmcblk0p2 rw rootwait cma=1536M"

CONFIG_SUBSYSTEM_ROOTFS_INITRD=n
CONFIG_SUBSYSTEM_ROOTFS_EXT4=y
CONFIG_SUBSYSTEM_SDROOT_DEV="/dev/mmcblk0p2"
CONFIG_SUBSYSTEM_RFS_FORMATS="tar.gz ext4 ext4.gz "
```

2. Append the following lines to `project-spec/configs/rootfs_config`:

```
# Add coreutils for full version of dd, and nvme-cli for NVMe tools

CONFIG_coreutils=y
CONFIG_nvme-cli=y
```

3. Append the following lines to file `project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg`:

```
# Kernel config specific to Zynq UltraScale+ designs

CONFIG_PCI_REALLOC_ENABLE_AUTO=y
CONFIG_PCIE_XDMA_PL=y
CONFIG_NVME_CORE=y
CONFIG_BLK_DEV_NVME=y
CONFIG_NVME_TARGET=y
```

### Mods for PicoZed FMC Carrier

These modifications are specific to the PicoZed FMC carrier BSP.

1. Append the following lines to `project-spec/configs/config`.

```
# PZ configs

CONFIG_USER_LAYER_0=""
CONFIG_SUBSYSTEM_USER_CMDLINE="earlycon console=ttyPS0,115200 clk_ignore_unused root=/dev/mmcblk1p2 rw rootwait cma=1536M"
CONFIG_SUBSYSTEM_SDROOT_DEV="/dev/mmcblk1p2"
```

2. Overwrite the device tree file 
   `project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi` with the one that is in the
   repository.

3. Overwrite the U-Boot config file `project-spec/meta-user/recipes-bsp/u-boot/files/bsp.cfg` with
   the following:
```
CONFIG_SYS_CONFIG_NAME="platform-top"

CONFIG_CMD_EEPROM=y
CONFIG_I2C_EEPROM=y
CONFIG_SYS_I2C_EEPROM_BUS=0
CONFIG_SYS_EEPROM_SIZE=256
CONFIG_SYS_I2C_EEPROM_ADDR=0x51
CONFIG_SYS_I2C_EEPROM_ADDR_OVERFLOW=0x0
CONFIG_SYS_I2C_EEPROM_ADDR_LEN=1
CONFIG_SYS_I2C_XILINX_XIIC=y
CONFIG_ZYNQ_MAC_IN_EEPROM=y
CONFIG_ZYNQ_GEM_I2C_MAC_OFFSET=0xFA
CONFIG_NET_RANDOM_ETHADDR=n

CONFIG_BOOT_SCRIPT_OFFSET=0xFC0000
```

4. Append the following to the kernel configuration file
   `project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg`:
```
# Required by PZ BSP
CONFIG_USB_ACM=y
CONFIG_USB_F_ACM=m
CONFIG_USB_U_SERIAL=m
CONFIG_USB_CDC_COMPOSITE=m
CONFIG_I2C_XILINX=y
```

### Mods for ZCU104

These modifications are specific to the ZCU104 BSP.

1. Add patch for FSBL to `project-spec/meta-user/recipes-bsp/embeddedsw/`. You will have to update this
   patch for the version of PetaLinux that you are using. Refer to the existing patch files in that
   location for guidance.
   
```
project-spec
           +--- meta-user
                        +--- recipes-bsp
                                       +--- embeddedsw
                                                     +--- files
                                                     |        +--- zcu104_vadj_fsbl.patch
                                                     +--- fsbl-firmware_%.bbappend
```

### Mods for ZCU106

These modifications are specific to the ZCU106 BSP.

1. Append the following lines to `project-spec/configs/config`. The first option prevents the removal of
   the PL DTB nodes that we need in this design. The second option disables the FPGA manager.

```
# ZCU106 configs

CONFIG_SUBSYSTEM_REMOVE_PL_DTB=n
CONFIG_SUBSYSTEM_FPGA_MANAGER=n
```

### Mods for UltraZed-EV Carrier

These modifications are specific to the UltraZed-EV BSP.

1. Append the following lines to `project-spec/configs/config`.

```
# UZ-EV configs

CONFIG_YOCTO_MACHINE_NAME="zynqmp-generic"
CONFIG_USER_LAYER_0=""
CONFIG_SUBSYSTEM_SDROOT_DEV="/dev/mmcblk1p2"
CONFIG_SUBSYSTEM_USER_CMDLINE=" earlycon console=ttyPS0,115200 clk_ignore_unused root=/dev/mmcblk1p2 rw rootwait cma=1000M"
CONFIG_SUBSYSTEM_PRIMARY_SD_PSU_SD_0_SELECT=n
CONFIG_SUBSYSTEM_PRIMARY_SD_PSU_SD_1_SELECT=y
CONFIG_SUBSYSTEM_SD_PSU_SD_0_SELECT=n
```

2. Append the following lines to `project-spec/meta-user/conf/petalinuxbsp.conf`.

```
IMAGE_BOOT_FILES:zynqmp = "BOOT.BIN boot.scr Image system.dtb"
```

3. Overwrite the device tree file 
   `project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi` with the one that is in the
   repository.


[Xilinx downloads]: https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html
[Avnet downloads]: https://avnet.me/zedsupport

