SDK Project files
=================

### Depreciation note

Starting with version 2019.2 of the Xilinx tools, the SDK was made part of the Vitis
unified software platform. We are currently migrating our standalone applications
to the Vitis software. Until the migration is completed, the sources in this repository
can still be used with the Xilinx SDK version 2019.1 if so desired. In other words,
the Vivado projects can be built with Vivado 2019.2, then exported to SDK 2019.1. The
export process must be done by Tcl script, because the Vivado 2019.2 GUI Hardware 
Export option generates a .XSA file, while the SDK expects a .HDF file.

To export a Vivado 2019.2 project for SDK 2019.1, first open the project in Vivado
and generate the bitstream. Once the bitstream generation is complete, open the Tcl
console tab in Vivado then copy-and-paste the following Tcl commands:

```
set proj_path [get_property DIRECTORY [current_project]]
set proj_name [get_property NAME [current_project]]
set top_module_name [get_property top [current_fileset]]
set bit_filename [lindex [glob -dir "${proj_path}/${proj_name}.runs/impl_1" *.bit] 0]
set export_dir "${proj_path}/${proj_name}.sdk"
set hwdef_filename "${proj_path}/${proj_name}.runs/impl_1/$top_module_name.hwdef"
set bit_filename "${proj_path}/${proj_name}.runs/impl_1/$top_module_name.bit"
set mmi_filename "${proj_path}/${proj_name}.runs/impl_1/$top_module_name.mmi"
file mkdir $export_dir
write_sysdef -force -hwdef $hwdef_filename -bitfile $bit_filename -meminfo $mmi_filename $export_dir/$top_module_name.hdf
```

Note that the .HDF file is generated regardless of the warning message 
`WARNING: [Common 17-210] 'write_sysdef' is deprecated.`.

Those Tcl commands will create a .sdk directory within the project directory, and then
generate a .hdf file in that directory. The `build-sdk.tcl` script can then be run from
the SDK directory to build the SDK workspace (see the following instructions).

### How to build the SDK workspace

In order to make use of these source files, you must first generate
the Vivado project hardware design (the bitstream) and export the design
to SDK. Check the `Vivado` folder for instructions on doing this from Vivado.

Once the bitstream is generated and exported to SDK, then you can build the
SDK workspace using the provided `build-sdk.tcl` script.

### Scripted build

The SDK directory contains a `build-sdk.tcl` script which can be run to automatically
generate the SDK workspace. Windows users can run the `build-sdk.bat` file which
launches the Tcl script. Linux users must use the following commands to run the build
script:
```
cd <path-to-repo>/SDK
/<path-to-xilinx-tools>/SDK/2019.1/bin/xsdk -batch -source build-sdk.tcl
```

The build script does four things:

1. Makes a copy of the `axipcie` driver from 
`{SDK Install Dir}\data\embeddedsw\XilinxProcessorIPLib\drivers\` to the repo's local 
directory `\EmbeddedSw\XilinxProcessorIPLib\drivers\`. Files that are already there
as part of the repo are not overwritten, which allows us to keep a modified version
of the driver. This modified version of the driver is used by the projects using the
Gen3 core (AXI Bridge for PCIe Gen3 IP). See below for more information.
2. Generates a Hello World example application for each exported Vivado design
that is found in the ../Vivado directory. Most users will only have one exported
Vivado design.
3. Deletes the `helloworld.c` source file from the application.
4. Copies either `pcie_gen2_enumeration.c` or `pcie_gen2_enumeration.c` from the
`\SDK\common\src\` directory of this repo into the application source directory.

### Run the application

1. Open Xilinx SDK.
2. Power up your hardware platform and ensure that the JTAG is
connected properly.
3. Select Xilinx Tools->Program FPGA. You only have to do this
once, each time you power up your hardware platform.
4. Select Run->Run to run your application. You can modify the code
and click Run as many times as you like, without going through
the other steps.

### Driver for AXI Bridge for PCIe Gen3 IP

Some of the Vivado designs in this project use the AXI Memory Mapped to PCIe Gen2 IP
and others use the AXI Bridge for PCIe Gen3 IP. The XSDK comes with a driver for the Gen2
core that is called `axipcie`. The BSPs for projects using the Gen2 core refer to that 
driver. You can find the driver sources in the XSDK installation files:

`{SDK Install Dir}\data\embeddedsw\XilinxProcessorIPLib\drivers\`

The XSDK does not currently supply a driver for the Gen3 core, so we have to create our
own. Luckily, there are enough similarities between the Gen2 and Gen3 cores that we can 
get away with using a modified version of the `axipcie` driver on the Gen3 core. This 
will allow us to do some simple things such as link-up detection, determining link speed
and width, and enumerating PCIe devices.

We create this "Gen3 version" of the driver by making a local copy of the `axipcie` driver
sources and modifying the `.mdd` file, specifying that the driver supports the Gen3 core.
For SDK to be aware of our locally copied driver, we set the SDK's repository path to the path 
of the driver. The `build-sdk.tcl` script handles the copying and modification of the 
`axipcie` driver, which is stored locally in the `EmbeddedSw/XilinxProcessorIPLib/drivers` 
directory.

### UART configurations

* Zynq & ZynqMP designs: 115200 baud
* Microblaze designs: 115200 baud

