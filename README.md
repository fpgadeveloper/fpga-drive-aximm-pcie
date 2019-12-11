fpga-drive-aximm-pcie
=====================

This repo contains the example designs for the FPGA Drive FMC mated with several FPGA and MPSoC evaluation boards.

![FPGA Drive FMC](http://fpgadrive.com/wp-content/uploads/2018/10/fpga-drive-fmc-3.jpg "FPGA Drive FMC")

## Requirements

This project is designed for version 2019.2 of the Xilinx tools (Vivado/Vitis/PetaLinux). 
If you are using an older version of the Xilinx tools, then refer to the 
[release tags](https://github.com/fpgadeveloper/fpga-drive-aximm-pcie/releases "releases")
to find the version of this repository that matches your version of the tools.

In order to test this design on hardware, you will need the following:

* Vivado 2019.2
* [FPGA Drive](http://fpgadrive.com "FPGA Drive") - for connecting a PCIe SSD
* M.2 PCIe Solid State Drive
* One of the supported carriers listed below

## Supported carrier boards

* Zynq-7000 [PicoZed FMC Carrier Card V2](http://zedboard.org/product/picozed-fmc-carrier-card-v2 "PicoZed FMC Carrier Card V2") with [PicoZed 7015/30](http://picozed.org "PicoZed")
  * PCIe edge - Single SSD
  * LPC connector - Single SSD
* Kintex-7 [KC705 Evaluation board](http://www.xilinx.com/products/boards-and-kits/ek-k7-kc705-g.html "KC705 Evaluation board")
  * PCIe edge - Single SSD
  * LPC connnector - Single SSD
  * HPC connnector - Single SSD
* Kintex Ultrascale [KCU105 Evaluation board](http://www.xilinx.com/products/boards-and-kits/kcu105.html "KCU105 Evaluation board")
  * LPC connnector - Single SSD
  * HPC connnector - Single and Dual SSD designs
* Virtex-7 [VC707 Evaluation board](http://www.xilinx.com/products/boards-and-kits/ek-v7-vc707-g.html "VC707 Evaluation board")
  * PCIe edge (use vc707.xdc)
  * HPC connector 1 - Single SSD
  * HPC connector 2 - Single SSD
* Virtex-7 [VC709 Evaluation board](http://www.xilinx.com/products/boards-and-kits/dk-v7-vc709-g.html "VC709 Evaluation board")
  * PCIe edge - Single SSD
  * HPC connector - Single SSD
* Zynq-7000 [ZC706 Evaluation board](http://www.xilinx.com/products/boards-and-kits/ek-z7-zc706-g.html "ZC706 Evaluation board")
  * PCIe edge - Single SSD
  * LPC connector - Single SSD
  * HPC connector - Single SSD
* Zynq UltraScale+ MPSoC [ZCU104 Evaluation board](https://www.xilinx.com/products/boards-and-kits/zcu104.html "ZCU104 Evaluation board")
  * LPC connector - Single SSD
* Zynq UltraScale+ MPSoC [ZCU106 Evaluation board](https://www.xilinx.com/products/boards-and-kits/zcu106.html "ZCU106 Evaluation board")
  * HPC connector 0 - Single and Dual SSD designs
  * HPC connector 1 - Single SSD
* Zynq UltraScale+ RFSoC [ZCU111 Evaluation board](https://www.xilinx.com/products/boards-and-kits/zcu111.html "ZCU111 Evaluation board")
  * FMC+ connector - Single and Dual SSD designs

## Description

These are the example designs for the FPGA Drive and FPGA Drive FMC adapters that allow connecting
NVMe SSDs to FPGAs via PCIe edge connectors and FPGA Mezzanine Card (FMC) connectors.

The bare metal software application reports on the status of the PCIe link and 
performs enumeration of the detected PCIe end-points (ie. the SSDs). The project also contains
scripts to generate PetaLinux for these platforms to allow accessing the SSDs from the Linux
operating system.

### Single SSD designs

![FPGA Drive FMC single load](http://fpgadrive.com/wp-content/uploads/2018/10/fpga-drive-fmc-single-load.jpg "FPGA Drive FMC single load")

The projects in this repo without the "_dual" postfix are intended to be used with only one loaded SSD as
shown in the above image. The SSD should be loaded into the first M.2 slot, labelled SSD1. If you are using 
the older version FPGA Drive FMC (Rev-B) with only one M.2 connector, you will only be able to use the single SSD designs.

### Dual SSD designs

![FPGA Drive FMC dual load](http://fpgadrive.com/wp-content/uploads/2018/10/fpga-drive-fmc-dual-load.jpg "FPGA Drive FMC dual load")

The projects in this repo with the "_dual" postfix are intended to be used with two loaded SSDs as shown
in the above image. The dual designs may not function as expected if only one SSD is loaded. If you are using the 
older version FPGA Drive FMC (Rev-B) with only one M.2 connector, you will not be able to use the dual designs.

At the moment there are dual designs for these carriers:
* KCU105
* ZCU106
* ZCU111

### Build instructions

To use the sources in this repository, please follow these steps:

### Windows users

1. Download the repo as a zip file and extract the files to a directory
   on your hard drive --OR-- Git users: clone the repo to your hard drive
2. Open Windows Explorer, browse to the repo files on your hard drive.
3. In the Vivado directory, you will find multiple batch files (*.bat).
   Double click on the batch file that is appropriate to your hardware,
   for example, double-click `build-zedboard.bat` if you are using the ZedBoard.
   This will generate a Vivado project for your hardware platform.
4. Run Vivado and open the project that was just created.
5. Click Generate bitstream.
6. When the bitstream is successfully generated, select `File->Export->Export Hardware`.
   In the window that opens, tick "Include bitstream" and "Local to project".
7. Return to Windows Explorer and browse to the SDK directory in the repo.
8. Double click the `build-sdk.bat` batch file. The batch file will run the
   `build-sdk.tcl` script and build the SDK workspace containing the hardware
   design and the software application.
9. Run Xilinx SDK (DO NOT use the Launch SDK option from Vivado) and select the workspace to be the SDK directory of the repo.
10. Select `Project->Build automatically`.
11. Connect and power up the hardware.
12. Open a Putty terminal to view the UART output.
13. In the SDK, select `Xilinx Tools->Program FPGA`.
14. Right-click on the application and select `Run As->Launch on Hardware (System Debugger)`

### Linux users

1. Download the repo as a zip file and extract the files to a directory
   on your hard drive --OR-- Git users: clone the repo to your hard drive
2. Launch the Vivado GUI.
3. Open the Tcl console from the Vivado welcome page. In the console, `cd` to the repo files
   on your hard drive and into the Vivado subdirectory. For example: `cd /media/projects/fpga-drive-aximm-pcie/Vivado`.
3. In the Vivado subdirectory, you will find multiple Tcl files. To list them, type `exec ls {*}[glob *.tcl]`.
   Determine the Tcl script for the example project that you would like to generate (for example: `build-zcu104.tcl`), 
   then `source` the script in the Tcl console: For example: `source build-zcu104.tcl`
4. Vivado will run the script and generate the project. When it's finished, click Generate bitstream.
5. When the bitstream is successfully generated, select `File->Export->Export Hardware`.
   In the window that opens, tick "Include bitstream" and "Local to project".
6. To build the SDK workspace, open a Linux command terminal and `cd` to the SDK directory in the repo.
7. The SDK directory contains the `build-sdk.tcl` script that will build the SDK workspace containing the hardware design and
   the software application. Run the build script by typing the following command: 
   `<path-of-xilinx-sdk>/bin/xsdk -batch -source build-sdk.tcl`. Note that you must replace `<path-of-xilinx-sdk>` with the 
   actual path to your Xilinx SDK installation.
8. Run Xilinx SDK (DO NOT use the Launch SDK option from Vivado) and select the workspace to be the SDK subdirectory of the 
   repo.
10. Select `Project->Build automatically`.
11. Connect and power up the hardware.
12. Open a Putty terminal to view the UART output.
13. In the SDK, select `Xilinx Tools->Program FPGA`.
14. Right-click on the application and select `Run As->Launch on Hardware (System Debugger)`

## Board Specific Notes

### KCU105

* To keep these designs free of paid IP, the KCU105's on-board Ethernet port is not connected in this design. The 
KCU105's Ethernet PHY has an SGMII interface which is not supported by the free AXI EthernetLite IP.

### VC709 and KCU105

These designs are based on the [AXI Bridge for PCI Express Gen3 Subsystem](http://www.xilinx.com/support/documentation/ip_documentation/axi_pcie3/v3_0/pg194-axi-bridge-pcie-gen3.pdf "AXI Bridge for PCI Express Gen3 Subsystem v3.0")
. To generate an example stand-alone application for these boards,
the SDK build script makes a local copy of the driver for the [AXI Memory Mapped to PCIe Gen2 IP](https://www.xilinx.com/products/intellectual-property/axi_pcie.html "AXI Memory Mapped to PCIe Gen2 IP")
with a few small modifications to make it work with the Gen3 core. If you use or modify these applications, be aware
that they refer to the locally copied and modified driver located in `EmbeddedSw/XilinxProcessorIPLib/drivers`, and that
that driver is actually designed for the Gen2 core. In other words, you can expect the driver to work for the example
application that checks link-up, link speed/width and enumerates the end points, but anything else may fail due to
differences between the driver code and the Gen3 IP specs.

### PicoZed

#### Installation of PicoZed board definition files

To use this project on the PicoZed, you must first install the board definition files
for the PicoZed into your Vivado installation.

The following folders contain the board definition files and can be found in this project repository at this location:

https://github.com/fpgadeveloper/fpga-drive-aximm-pcie/tree/master/Vivado/boards/board_files

* `picozed_7015_fmc2`
* `picozed_7030_fmc2`

Copy those folders and their contents into the `C:\Xilinx\Vivado\2019.2\data\boards\board_files` folder (this may
be different on your machine, depending on your Vivado installation directory).

### PicoZed FMC Carrier Card V2

On this carrier, the GBTCLK0 of the LPC FMC connector is routed to a clock synthesizer/MUX, rather than being directly
connected to the Zynq. In order to use the FPGA Drive FMC on the [PicoZed FMC Carrier Card V2](http://zedboard.org/product/picozed-fmc-carrier-card-v2 "PicoZed FMC Carrier Card V2"), 
you will need to reconfigure the clock synthesizer so that it feeds the FMC clock through to the Zynq. To change the configuration,
you must reprogram the EEPROM (U14) where the configuration is stored. Avnet provides an SD card boot file that can be run to
reprogram the EEPROM to the configuration we need for this project. The boot files have been copied to the links below for your
convenience:

* [PicoZed 7015 BOOT.bin for FMC clock config](https://opsero.com/downloads/picozed/pz_7015_fmc_clock.zip "PicoZed 7015 BOOT.bin for FMC clock config")
* [PicoZed 7030 BOOT.bin for FMC clock config](https://opsero.com/downloads/picozed/pz_7030_fmc_clock.zip "PicoZed 7030 BOOT.bin for FMC clock config")

Just boot up your [PicoZed FMC Carrier Card V2](http://zedboard.org/product/picozed-fmc-carrier-card-v2 "PicoZed FMC Carrier Card V2")
using one of those boot files, and the EEPROM will be reprogrammed as required for this project. For more information,
see the [Hardware User Guide](http://zedboard.org/sites/default/files/documentations/5285-UG-PZCC-FMC-V2-V1_1.pdf "Hardware User Guide")
for the [PicoZed FMC Carrier Card V2](http://zedboard.org/product/picozed-fmc-carrier-card-v2 "PicoZed FMC Carrier Card V2").

### ZCU106

The ZCU106 has two HPC FMC connectors, HPC0 and HPC1. The HPC0 connector has enough connected gigabit transceivers to support
2x SSDs, each with an independent 4-lane PCIe interface. The HPC1 connector has only 1x connected gigabit transceiver, so it can only
support 1x SSD (SSD1) with a 1-lane PCIe interface. This repo contains designs for both of these connectors.

The designs for the ZCU106 are based on the DMA/Bridge Subsystem for PCIe IP, for which there is no standalone driver at the time
of writing. For this reason, this repo does not contain standalone applications for these designs. The designs can however be used
with PetaLinux, and the scripts contained in this repo will generate PetaLinux projects for them.

### ZCU111

The ZCU111 has a single FMC+ connector that can support 2x SSDs, each with an independent 4-lane PCIe interface.

The designs for the ZCU111 are based on the DMA/Bridge Subsystem for PCIe IP, for which there is no standalone driver at the time
of writing. For this reason, this repo does not contain standalone applications for these designs. The designs can however be used
with PetaLinux, and the scripts contained in this repo will generate PetaLinux projects for them.

## Troubleshooting

Check the following if the project fails to build or generate a bitstream:

### 1. Are you using the correct version of Vivado for this version of the repository?
Check the version specified in the Requirements section of this readme file. Note that this project is regularly maintained to the latest
version of Vivado and you may have to refer to an earlier commit of this repo if you are using an older version of Vivado.

### 2. Did you follow the Build instructions in this readme file?
All the projects in the repo are built, synthesised and implemented to a bitstream before being committed, so if you follow the
instructions, there should not be any build issues.

### 3. Did you copy/clone the repo into a short directory structure?
Vivado doesn't cope well with long directory structures, so copy/clone the repo into a short directory structure such as
`C:\projects\`. When working in long directory structures, you can get errors relating to missing files, particularly files 
that are normally generated by Vivado (FIFOs, etc).

## Contribute

We encourage contribution to these projects. If you spot issues or you want to add designs for other platforms, please
make a pull request.

### About us

This project was developed by [Opsero Inc.](http://opsero.com "Opsero Inc."),
a tight-knit team of FPGA experts delivering FPGA products and design services to start-ups and tech companies. 
Follow our blog, [FPGA Developer](http://www.fpgadeveloper.com "FPGA Developer"), for news, tutorials and
updates on the awesome projects we work on.