==================
Build instructions
==================

Source code
-----------

The source code for the reference designs is managed on this Github repository:
`https://github.com/fpgadeveloper/fpga-drive-aximm-pcie <https://github.com/fpgadeveloper/fpga-drive-aximm-pcie>`_

Windows users
-------------

#. Download the repo as a zip file and extract the files to a directory
   on your hard drive --OR-- Git users: clone the repo to your hard drive
#. Open Windows Explorer, browse to the repo files on your hard drive.
#. In the Vivado directory, you will find multiple batch files (.bat).
   Double click on the batch file that is appropriate to your hardware,
   for example, double-click ``build-zedboard.bat`` if you are using the ZedBoard.
   This will generate a Vivado project for your hardware platform.
#. Run Vivado and open the project that was just created.
#. Click Generate bitstream.
#. When the bitstream is successfully generated, select `File->Export->Export Hardware`.
   In the window that opens, tick "Include bitstream" and "Local to project".
#. Return to Windows Explorer and browse to the Vitis directory in the repo.
#. Double click the ``build-vitis.bat`` batch file. The batch file will run the
   ``build-vitis.tcl`` script and build the Vitis workspace containing the hardware
   design and the software application.
#. Run Xilinx Vitis and select the workspace to be the Vitis directory of the repo.
#. Connect and power up the hardware.
#. Open a Putty terminal to view the UART output.
#. In Vitis, select `Xilinx Tools->Program FPGA`.
#. Right-click on the application and select `Run As->Launch on Hardware (Single Application Debug)`

Linux users
-----------

#. Download the repo as a zip file and extract the files to a directory
   on your hard drive --OR-- Git users: clone the repo to your hard drive
#. Launch the Vivado GUI.
#. Open the Tcl console from the Vivado welcome page. In the console, ``cd`` to the repo files
   on your hard drive and into the Vivado subdirectory. For example: ``cd /media/projects/fpga-drive-aximm-pcie/Vivado``.
#. In the Vivado subdirectory, you will find multiple Tcl files. To list them, type ``exec ls {*}[glob *.tcl]``.
   Determine the Tcl script for the example project that you would like to generate (for example: ``build-zedboard.tcl``), 
   then ``source`` the script in the Tcl console: For example: ``source build-zedboard.tcl``
#. Vivado will run the script and generate the project. When it's finished, click Generate bitstream.
#. When the bitstream is successfully generated, select `File->Export->Export Hardware`.
   In the window that opens, tick "Include bitstream" and "Local to project".
#. To build the Vitis workspace, open a Linux command terminal and ``cd`` to the Vitis directory in the repo.
#. The Vitis directory contains the ``build-vitis.tcl`` script that will build the Vitis workspace containing the hardware design and
   the software application. Run the build script by typing the following command: 
   ``<path-of-xilinx-vitis>/bin/xsct build-vitis.tcl``. Note that you must replace ``<path-of-xilinx-vitis>`` with the 
   actual path to your Xilinx Vitis installation.
#. Run Xilinx Vitis and select the workspace to be the Vitis subdirectory of the 
   repo.
#. Connect and power up the hardware.
#. Open a Putty terminal to view the UART output.
#. In Vitis, select `Xilinx Tools->Program FPGA`.
#. Right-click on the application and select `Run As->Launch on Hardware (Single Application Debug)`

