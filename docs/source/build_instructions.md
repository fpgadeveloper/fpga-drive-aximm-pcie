# Build instructions

## Source code

The source code for the reference designs is managed on this Github repository:
[https://github.com/fpgadeveloper/fpga-drive-aximm-pcie](https://github.com/fpgadeveloper/fpga-drive-aximm-pcie)

## Windows users

1. Download the repo as a zip file and extract the files to a directory
   on your hard drive --OR-- clone the repo to your hard drive
2. Open Windows Explorer, browse to the repo files on your hard drive.
3. In the Vivado directory, you will find multiple batch files (.bat).
   Double click on the batch file that corresponds to your hardware,
   for example, double-click `build-zedboard.bat` if you are using the ZedBoard.
   This will generate a Vivado project for your hardware platform.
4. Run Vivado and open the project that was just created.
5. Click Generate bitstream.
6. When the bitstream is successfully generated, select **File->Export->Export Hardware**.
   In the window that opens, tick "Include bitstream" and "Local to project".
7. Return to Windows Explorer and browse to the Vitis directory in the repo.
8. Double click the `build-vitis.bat` batch file. The batch file will run the
   `build-vitis.tcl` script and build the Vitis workspace containing the hardware
   design and the software application.
9. Run Xilinx Vitis and select the workspace to be the Vitis directory of the repo.
10. Connect and power up the hardware.
11. Open a Putty terminal to view the UART output.
12. In Vitis, select **Xilinx Tools->Program FPGA**.
13. Right-click on the application and select **Run As->Launch on Hardware (Single Application Debug)**

## Linux users

1. Download the repo as a zip file and extract the files to a directory
   on your hard drive --OR-- clone the repo to your hard drive
2. Launch the Vivado GUI.
3. Open the Tcl console from the Vivado welcome page. In the console, `cd` to the repo files
   on your hard drive and into the Vivado subdirectory. For example: `cd /media/projects/fpga-drive-aximm-pcie/Vivado`.
4. In the Vivado subdirectory, you will find multiple Tcl files. To list them, type `exec ls {*}[glob *.tcl]`.
   Determine the Tcl script for the example project that you would like to generate (for example: `build-zedboard.tcl`), 
   then `source` the script in the Tcl console: For example: `source build-zedboard.tcl`
5. Vivado will run the script and generate the project. When it's finished, click Generate bitstream.
6. When the bitstream is successfully generated, select `File->Export->Export Hardware`.
   In the window that opens, tick "Include bitstream" and "Local to project".
7. To build the Vitis workspace, open a Linux command terminal and `cd` to the Vitis directory in the repo.
8. The Vitis directory contains the `build-vitis.tcl` script that will build the Vitis workspace containing the hardware design and
   the software application. Run the build script by typing the following command: 
   `<path-of-xilinx-vitis>/bin/xsct build-vitis.tcl`. Note that you must replace `<path-of-xilinx-vitis>` with the 
   actual path to your Xilinx Vitis installation.
9. Run Xilinx Vitis and select the workspace to be the Vitis subdirectory of the 
   repo.
10. Connect and power up the hardware.
11. Open a Putty terminal to view the UART output.
12. In Vitis, select **Xilinx Tools->Program FPGA**.
13. Right-click on the application and select **Run As->Launch on Hardware (Single Application Debug)**

