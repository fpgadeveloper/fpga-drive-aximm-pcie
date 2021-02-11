Vitis Project files
===================

### How to build the Vitis workspace

In order to make use of these source files, you must first generate
the Vivado project hardware design (the bitstream) and export the hardware.
Check the `Vivado` folder for instructions on doing this from Vivado.

Once the bitstream is generated and exported, then you can build the
Vitis workspace using the provided `build-vitis.tcl` script.

### Scripted build

The Vitis directory contains a `build-vitis.tcl` script which can be run to automatically
generate the Vitis workspace. Windows users can run the `build-vitis.bat` file which
launches the Tcl script. Linux users must use the following commands to run the build
script:
```
cd <path-to-repo>/Vitis
/<path-to-xilinx-tools>/Vitis/2020.2/bin/xsct build-vitis.tcl
```

The build script does three things:

1. Creates a local software repository inside the Vitis workspace called `embeddedsw`.
It copies the modified driver sources from the Git repo's `EmbeddedSw` folder to the local 
software repository `embeddedsw`. Then it copies the rest of the required sources from
`{Vitis Install Dir}\data\embeddedsw\`. The `embeddedsw` local software repository holds
a modified version of the BSP libraries that are required by the application. For more
information about the modifications to the libraries, see the README in the `EmbeddedSw`
folder of this Git repository.
2. Generates an empty application for each exported Vivado design
that is found in the `../Vivado` directory. Most users will only have one exported
Vivado design.
3. Copies the appropriate enumeration application source file from the
`\Vitis\common\src\` directory of this repo into the application source directory.

### Run the application

1. Open Xilinx Vitis.
2. Power up your hardware platform and ensure that the JTAG is
connected properly.
3. In the Vitis Explorer panel, double-click on the System project that you want to run -
this will reveal the applications contained in the project. The System project will have 
the postfix "_system".
4. Now click on the application that you want to run. It should have the postfix "_ssd_test".
5. Select the option "Run Configurations" from the drop-down menu contained under the Run
button on the toolbar (play symbol).
6. Double-click on "Single Application Debug" to create a run configuration for this 
application. Then click "Run".

The run configuration will first program the FPGA with the bitstream, then load and run the 
application. You can view the UART output of the application in a console window.

### UART settings

To receive the UART output of this standalone application, you will need to connect the
USB-UART of the development board to your PC and run a console program such as 
[Putty](https://www.putty.org "Putty"). The follow UART settings must be used:

* Microblaze designs: 9600 baud
* Zynq and ZynqMP designs: 115200 baud

### Linker script modifications for Zynq designs

For the Zynq designs, the Vitis's linker script generator automatically assigns all sections
to the BAR0 memory space, instead of assigning them to the DDR memory space. This causes 
failure of the application to run, when booted from SD card or JTAG. To overcome this problem,
the Vitis build script modifies the generated linker script and correctly assigns the sections
to DDR memory.

If you want to manually create an application in the Vitis for one of the Zynq designs,
you will have to manually modify the automatically generated linker script, and set all sections
to DDR memory.
