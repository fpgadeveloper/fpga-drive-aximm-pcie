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
     version 2022.1, then the `<year>` should be 2022.
   * Update the year in all references to `Vivado Implementation <year>` to the 
     tools version number that you are using. For example, if you are using tools
     version 2022.1, then the `<year>` should be 2022.
3. In a text editor, open the `Vivado/scripts/xsa.tcl` file and perform the following changes:
   * Update the `version_required` variable value to the tools version number 
     that you are using.
4. **Windows users only:** In a text editor, open the `Vivado/build-<target>.bat` file for
   the design that you wish to update, and update the tools version number to the one you are using 
   (eg. 2022.1).

After completing the above, you should now be able to use the [build instructions](build_instructions) to
build the Vivado project. If there were no significant changes to the tools and/or IP, the build script 
should succeed and you will be able to open and generate a bitstream.

## PetaLinux

The main procedure for updating the PetaLinux project is to update the BSP for the target platform.
The BSP files for each supported target platform are contained in the `PetaLinux/bsp` directory.

1. Download and install the PetaLinux release that you intend to use.
2. Download and install the BSP for the target platform for the release that you intend to use.

   * For KC705, KCU105, ZC706, ZCU104, ZCU106, ZCU111, ZCU208 download the BSP from the 
     [Xilinx downloads] page
   * For PicoZed and UltraZed-EV contact your [Avnet rep](https://www.avnet.com)

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

### Mods for all Microblaze designs

The following modifications apply to all the Microblaze based designs (KC705, KCU105, VC707, VC709).

1. Append the following lines to file `project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg`:

```
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

### Mods for KC705

These modifications are specific to the KC705 BSP.

1. Append the following lines to `project-spec/configs/config`:

```
# KC705 configs

CONFIG_SUBSYSTEM_MACHINE_NAME="kc705-lite"

# Increase kernel partition size
CONFIG_SUBSYSTEM_FLASH_AXI_EMC_0_BANK0_PART3_SIZE=0xF00000
```

### Mods for KCU105

These modifications are specific to the KCU105 BSP.

1. Append the following lines to `project-spec/configs/config`:

```
# KCU105 configs

CONFIG_SUBSYSTEM_MACHINE_NAME="template"

# Reduce fpga (bitstream) partition size, increase kernel partition size
CONFIG_SUBSYSTEM_FLASH_AXI_QUAD_SPI_0_BANKLESS_PART0_SIZE=0xF00000
CONFIG_SUBSYSTEM_FLASH_AXI_QUAD_SPI_0_BANKLESS_PART3_SIZE=0xE00000
CONFIG_SUBSYSTEM_UBOOT_QSPI_FIT_IMAGE_OFFSET=0x10C0000
CONFIG_SUBSYSTEM_UBOOT_QSPI_FIT_IMAGE_SIZE=0xE00000
```

2. Append the following lines to file `project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`:

```
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
```

### Mods for PicoZed FMC Carrier

These modifications are specific to the PicoZed FMC carrier BSP.

1. Append the following lines to `project-spec/configs/config`.

```
# PZ configs

CONFIG_SUBSYSTEM_MACHINE_NAME="template"

# SD card for root filesystem

CONFIG_SUBSYSTEM_BOOTARGS_AUTO=n
CONFIG_SUBSYSTEM_USER_CMDLINE="earlycon console=ttyPS0,115200 clk_ignore_unused root=/dev/mmcblk1p2 rw rootwait cma=1536M"

CONFIG_SUBSYSTEM_ROOTFS_INITRD=n
CONFIG_SUBSYSTEM_ROOTFS_EXT4=y
CONFIG_SUBSYSTEM_SDROOT_DEV="/dev/mmcblk1p2"
CONFIG_SUBSYSTEM_RFS_FORMATS="tar.gz ext4 ext4.gz "
```

### Mods for ZCU104

These modifications are specific to the ZCU104 BSP.

1. Add patch for FSBL to `project-spec/meta-user/recipes-bsp/fsbl/`. You will have to update this
   patch for the version of PetaLinux that you are using. Refer to the existing patch files in that
   location for guidance.

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
# UZ configs

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

3. Replace the device tree file `project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`
   contents with the following:
   
```
#include "include/dt-bindings/input/input.h"
#include "include/dt-bindings/gpio/gpio.h"
#include "include/dt-bindings/pinctrl/pinctrl-zynqmp.h"
#include "include/dt-bindings/phy/phy.h"
#include "include/dt-bindings/interrupt-controller/irq.h"
/include/ "system-conf.dtsi"

/* From include/dt-bindings/clk/versaclock.h */
#define VC5_LVPECL   0
#define VC5_CMOS  1
#define VC5_HCSL33   2
#define VC5_LVDS  3
#define VC5_CMOS2 4
#define VC5_CMOSD 5
#define VC5_HCSL25   6

/ {
   model = "ZynqMP Ultrazed EV";
   xlnk {
      compatible = "xlnx,xlnk-1.0";
   };

   chosen {
      xlnx,eeprom= &mac_eeprom;
   };

   clock_5p49v5935_ref25: ref25m { /* 25MHz reference crystal (internal) - U3 */
      compatible = "fixed-clock";
      #clock-cells = <0>;
      clock-frequency = <25000000>;
   };

   gtr_clk0: gtr_clk0 { /* gtr_refclk0_pcie - 100MHz - U3 */
      compatible = "fixed-clock";
      #clock-cells = <0>;
      clock-frequency = <100000000>;
   };

   gtr_clk1: gtr_clk1 { /* gtr_refclk1_sata - 125MHz - U3 */
      compatible = "fixed-clock";
      #clock-cells = <0>;
      clock-frequency = <125000000>;
   };

   gtr_clk2: gtr_clk2 { /* gtr_refclk2_usb - 52MHz - U3 */
      compatible = "fixed-clock";
      #clock-cells = <0>;
      clock-frequency = <52000000>;
   };

   gtr_clk3: gtr_clk3 { /* gtr_refclk3_dp - 27MHz - U3 */
      compatible = "fixed-clock";
      #clock-cells = <0>;
      clock-frequency = <27000000>;
   };

};

&gem3 {
   status = "okay";
   phy-mode = "rgmii-id";
   phy-handle = <&phy0>;
   phy0: phy@0 {
      reg = <0x0>;
      ti,rx-internal-delay = <0x5>;
      ti,tx-internal-delay = <0x5>;
      ti,fifo-depth = <0x1>;
   };
};

&i2c1 {
   i2cswitch@70 { /* U7 on UZ3EG SOM, U8 on UZ7EV SOM */
      compatible = "nxp,pca9543";
      #address-cells = <1>;
      #size-cells = <0>;
      reg = <0x70>;
      i2c@0 { /* i2c mw 70 0 1 */
         #address-cells = <1>;
         #size-cells = <0>;
         reg = <0>;
         /* Ethernet MAC ID EEPROM */
         mac_eeprom: mac_eeprom@51 { /* U5 on UZ3EG IOCC & PCIEC and U7 on the UZ7EV EVCC */
            compatible = "atmel,24c02";
            reg = <0x51>;
         };

         vc5: clock-generator@6a { /* IDT (Renesas) 5P49V5935 I2C clock generator */
            compatible = "idt,5p49v5935";
            reg = <0x6a>;
            #clock-cells = <1>;

            /* Connect XIN input to 25MHz reference */
            clocks = <&clock_5p49v5935_ref25>;
            clock-names = "xin";

            OUT3 { /* USB3 */
               idt,drive-mode = <VC5_CMOSD>; /* */
               idt,voltage-microvolts = <1800000>;
               idt,slew-percent = <80>;
            };
         };

         
         clock_eeprom@52 { /* U5 on the UZ7EV EVCC */
            compatible = "atmel,24c02";
            reg = <0x52>;
         };
      };

      i2c@1 {
         #address-cells = <0x1>;
         #size-cells = <0x0>;
         reg = <0x1>;

         irps5401@46 { /* IRPS5401 - U24 on UZ7EV SOM*/
            compatible = "infineon,irps5401";
            reg = <0x46>;
         };

         irps5401@47 { /* IRPS5401 - U25 on UZ7EV SOM*/
            compatible = "infineon,irps5401";
            reg = <0x47>;
         };

         ir38063@48 { /* IR38063 - U26 on UZ7EV SOM*/
            compatible = "infineon,ir38063";
            reg = <0x48>;
         };

         irps5401@49 { /* IRPS5401 - U21 on UZ7EV EVCC*/
            compatible = "infineon,irps5401";
            reg = <0x49>;
         };
         irps5401@4a { /* IRPS5401 - U22 on UZ7EV EVCC*/
            compatible = "infineon,irps5401";
            reg = <0x4a>;
         };

         ir38063@4b { /* IR38063 - U18 on UZ7EV EVCC*/
            compatible = "infineon,ir38063";
            reg = <0x4b>;
         };

         ir38063@4c { /* IR38063 - U19 on UZ7EV EVCC*/
            compatible = "infineon,ir38063";
            reg = <0x4c>;
         };
      };
   };
};

&qspi {
   #address-cells = <1>;
   #size-cells = <0>;
   status = "okay";
   is-dual = <1>; /* Set for dual-parallel QSPI config */
   num-cs = <2>;
   xlnx,fb-clk = <0x1>;
   flash0: flash@0 {
      /* The Flash described below doesn't match our board ("micron,n25qu256a"), but is needed */
      /* so the Flash MTD partitions are correctly identified in /proc/mtd */
      compatible = "micron,m25p80","jedec,spi-nor"; /* 32MB */
      #address-cells = <1>;
      #size-cells = <1>;
      reg = <0x0>;
      spi-tx-bus-width = <1>;
      spi-rx-bus-width = <4>; /* FIXME also DUAL configuration possible */
      spi-max-frequency = <108000000>; /* Set to 108000000 Based on DC1 spec */
   };
};

/* SD0 eMMC, 8-bit wide data bus */
&sdhci0 {
   status = "okay";
   bus-width = <8>;
   max-frequency = <50000000>;
};

/* SD1 with level shifter */
&sdhci1 {
   status = "okay";
   max-frequency = <50000000>;
   no-1-8-v;   /* for 1.0 silicon */
   disable-wp;
   broken-cd;
   xlnx,mio-bank = <1>;
   /* Do not run SD in HS mode from bootloader */
   sdhci-caps-mask = <0 0x200000>;
   sdhci-caps = <0 0>;
};

&psgtr {
   /* PCIE, SATA, USB3, DP */
   clocks = <&gtr_clk0>, <&gtr_clk1>, <&gtr_clk2>, <&gtr_clk3>;
   clock-names = "ref0", "ref1", "ref2", "ref3";
};

/* ULPI SMSC USB3320 */
&usb0 {
   status = "okay";
};

&dwc3_0 {
   status = "okay"; 
   dr_mode = "host";
   maximum-speed = "super-speed"; 
   snps,usb3_lpm_capable; 
   snps,enable_auto_retry; 
   phy-names = "usb3-phy"; 
   /* <psgtr_phandle> <lane_number> <controller_type> <instance> <refclk> */
   phys = <&psgtr 2 PHY_TYPE_USB3 0 2>;
};

&sata {
   status = "okay";
   phy-names = "sata-phy";
   /* <psgtr_phandle> <lane_number> <controller_type> <instance> <refclk> */
   phys = <&psgtr 1 PHY_TYPE_SATA 1 1>;
};
```



[Xilinx downloads]: https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html

