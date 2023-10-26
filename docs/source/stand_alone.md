# Stand-alone Application

A stand-alone software application can be built for this project using the build script contained in the 
Vitis subdirectory of this repo. The build script creates a Vitis workspace containing the hardware platform 
(exported from Vivado) and a stand-alone application. The application originates from an example provided by 
Xilinx which is located in the Vitis installation files.
The program demonstrates basic usage of the stand-alone driver including how to check link-up, link speed, 
the number of lanes used, as well as how to perform PCIe enumeration. The original example applications can 
be found here:

* For the AXI PCIe designs:
  `<Xilinx-path>/Vitis/2022.1/data/embeddedsw/XilinxProcessorIPLib/drivers/axipcie_v3_3/examples/xaxipcie_rc_enumerate_example.c`
* For the XDMA designs:
  `<Xilinx-path>/Vitis/2022.1/data/embeddedsw/XilinxProcessorIPLib/drivers/xdmapcie_v1_5/examples/xdmapcie_rc_enumerate_example.c`

## Building the Vitis workspace

To build the Vitis workspace and example application, you must first generate
the Vivado project hardware design (the bitstream) and export the hardware.
Once the bitstream is generated and exported, then you can build the
Vitis workspace using the provided scripts. Follow the instructions appropriate for your
operating system:

* **Windows**: Follow the [build instructions for Windows users](/build_instructions.md#windows-users)
* **Linux**: Follow the [build instructions for Linux users](/build_instructions.md#linux-users)

## Hardware setup

Before running the application, you will need to setup the hardware.

1. Connect one or more SSDs to the [FPGA Drive FMC Gen4] and then plug it into the target board.
   Instructions for doing this can be found in the 
   [Getting started](https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/getting-started/) guide.
2. To receive the UART output of this standalone application, you will need to connect the
   USB-UART of the development board to your PC and run a console program such as 
   [Putty].
   * **For Microblaze designs:** The UART speed must be set to 9600.
   * **For Zynq and Zynq MPSoC/RFSoC designs:** The UART speed must be set to 115200.


## Run the application

You must have followed the build instructions before you can run the application.

1. Launch the Xilinx Vitis GUI.
2. When asked to select the workspace path, select the `Vitis/<target>_workspace` directory.
3. Power up your hardware platform and ensure that the JTAG is connected properly.
4. In the Vitis Explorer panel, double-click on the System project that you want to run -
   this will reveal the application contained in the project. The System project will have 
   the postfix "_system".
5. Now right click on the application "ssd_test" then navigate the
   drop down menu to **Run As->Launch on Hardware (Single Application Debug (GDB)).**.

![Vitis Launch on hardware](images/vitis-launch-on-hardware.png)

The run configuration will first program the FPGA with the bitstream, then load and run the 
application. You can view the UART output of the application in a console window and it should
appear as follows:

### Output of xdma designs

```none
Xilinx Zynq MP First Stage Boot Loader
Release 2022.1   Sep 25 2023  -  16:02:40
PMU-FW is not running, certain applications may not be supported.
Interrupts currently enabled are        0
Interrupts currently pending are        0
Interrupts currently enabled are        0
Interrupts currently pending are        0
Link is up
Bus Number is 00
Device Number is 00
Function Number is 00
Port Number is 00
PCIe Local Config Space is   100147 at register CommandStatus
PCIe Local Config Space is    70100 at register Prim Sec. Bus
Root Complex IP Instance has been successfully initialized
xdma_pcie:
PCIeBus is 00
PCIeDev is 00
PCIeFunc is 00
xdma_pcie: Vendor ID is 10EE
Device ID is 9131
xdma_pcie: This is a Bridge
xdma_pcie: bus: 0, device: 0, function: 0: BAR 0 is not implemented
xdma_pcie: bus: 0, device: 0, function: 0: BAR 1 is not implemented
xdma_pcie:
PCIeBus is 01
PCIeDev is 00
PCIeFunc is 00
xdma_pcie: Vendor ID is 144D
Device ID is A808
xdma_pcie: This is an End Point
xdma_pcie: bus: 1, device: 0, function: 0: BAR 0, ADDR: 0xA0000000 size : 16K
xdma_pcie: bus: 1, device: 0, function: 0: BAR 2 is not implemented
xdma_pcie: bus: 1, device: 0, function: 0: BAR 3 is not implemented
xdma_pcie: bus: 1, device: 0, function: 0: BAR 4 is not implemented
xdma_pcie: bus: 1, device: 0, function: 0: BAR 5 is not implemented
xdma_pcie: End Point has been enabled
Successfully ran XdmaPcie rc enumerate Example
```

### Output of axipcie designs

```none
=============================
PCIe Enumeration Example
=============================
Link:
  - LINK UP, Gen1 x1 lanes
Interrupts:
  - currently enabled:        0
  - currently pending:        0
Cleared pending interrupts:
  - currently enabled:        0
  - currently pending:        0
Requester ID:
  - Bus Number: 00
  - Device Number: 00
  - Function Number: 00
  - Port Number: 00
PCIe Local Config Space:
  -   100147 at register CommandStatus
  -    70100 at register Prim Sec. Bus
Enumeration of PCIe Fabric:
PCIeBus 00:
  - PCIeDev: 00
  - PCIeFunc: 00
  - Vendor ID: 10EE
  - Bridge
PCIeBus 01:
  - PCIeDev: 00
  - PCIeFunc: 00
  - Vendor ID: 144D
  - End Point
  - End Point has been enabled
End of Enumeration
```

## Advanced Design Details

### Linker script modifications for Zynq designs

For the Zynq designs, the Vitis's linker script generator automatically assigns all sections
to the BAR0 memory space, instead of assigning them to the DDR memory space. This causes 
failure of the application to run, when booted from SD card or JTAG. To overcome this problem,
the Vitis build script modifies the generated linker script and correctly assigns the sections
to DDR memory.

If you want to manually create an application in the Vitis for one of the Zynq designs,
you will have to manually modify the automatically generated linker script, and set all sections
to DDR memory.

### axipcie driver

This project uses a modified version of the axipcie driver.

The `axipcie_v3_3` driver is attached to designs that use the AXI Memory Mapped to PCIe IP (axi_pcie) and 
designs that use the AXI PCIe Gen3 IP (axi_pcie3). However, the driver contains a bug that affects designs
that use the AXI PCIe Gen3 IP.

The script `axipcie_v3_3/data/acipcie.tcl` generates the `xparameters.h` and `xaxipcie_g.c` BSP sources that
both contain a define called `INCLUDE_RC`. To determine the value of this define, the script reads a parameter of 
the PCIe IP called `CONFIG.INCLUDE_RC`, however this parameter only exists in the AXI Memory Mapped to PCIe IP.
Our modified version of the script uses the correct parameter to determine the value of `INCLUDE_RC`.
Specifically, it reads the `CONFIG.device_port_type` parameter and compares it to the value that is expected
for root complex designs: `Root_Port_of_PCI_Express_Root_Complex`.


[Putty]: https://www.putty.org/
[FPGA Drive FMC Gen4]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/

