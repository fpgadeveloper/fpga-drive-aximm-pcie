SDK Project files
=================

### How to build the SDK workspace

In order to make use of these source files, you must first generate
the Vivado project hardware design (the bitstream) and export the design
to SDK. Check the `Vivado` folder for instructions on doing this from Vivado.

Once the bitstream is generated and exported to SDK, then you can build the
SDK workspace using the provided `build-sdk.tcl` script.

### Scripted build

The SDK directory contains a `build-sdk.tcl` script which can be run to automatically
generate the SDK workspace. Windows users can run the `build-sdk.bat` file which
launches the Tcl script.

The build script does three things:
1. Generates a Hello World example application for each exported Vivado design
that is found in the ../Vivado directory. Most users will only have one exported
Vivado design.
2. Deletes the `helloworld.c` source file from the application.
3. Copies the `C:\Xilinx\SDK\<version>\data\embeddedsw\XilinxProcessorIPLib\drivers\axipcie_v${drv_ver}\examples\xaxipcie_rc_enumerate_example.c`
source file into the application source directory.

### Run the application

1. Open Xilinx SDK.
2. Power up your hardware platform and ensure that the JTAG is
connected properly.
3. Select Xilinx Tools->Program FPGA. You only have to do this
once, each time you power up your hardware platform.
4. Select Run->Run to run your application. You can modify the code
and click Run as many times as you like, without going through
the other steps.

