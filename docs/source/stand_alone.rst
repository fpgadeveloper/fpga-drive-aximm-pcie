================================
Stand-alone Application
================================

A stand-alone software application can be built for this project using the build script contained in the Vitis subdirectory
of this repo. The build script creates a Vitis workspace containing the hardware platform (exported from Vivado) and a stand-alone
application. The application originates from an example provided by Xilinx which is located in the Vitis installation files.
The program demonstrates basic usage of the stand-alone driver including how to check link-up, link speed, the number of 
lanes used, as well as how to perform PCIe enumeration. The original example applications can be found here:

* For the AXI PCIe designs:
  ``C:\Xilinx\Vitis\2020.2\data\embeddedsw\XilinxProcessorIPLib\drivers\axipcie_v3_3\examples\xaxipcie_rc_enumerate_example.c``
* For the XDMA designs:
  ``C:\Xilinx\Vitis\2020.2\data\embeddedsw\XilinxProcessorIPLib\drivers\xdmapcie_v1_2\examples\xdmapcie_rc_enumerate_example.c``

Building the Vitis workspace
================================

To build the Vitis workspace and example application, you must first generate
the Vivado project hardware design (the bitstream) and export the hardware.
Once the bitstream is generated and exported, then you can build the
Vitis workspace using the provided ``Vitis/build-vitis.tcl`` script.

Windows users
-------------

To build the Vitis workspace, Windows users can run the ``build-vitis.bat`` file which
launches the Tcl script.

Linux users
-----------

Linux users must use the following commands to run the build script:

.. code-block::

  cd <path-to-repo>/Vitis
  /<path-to-xilinx-tools>/Vitis/2020.2/bin/xsct build-vitis.tcl

What the script does
--------------------

The build script does three things:

#. Creates a local software repository inside the Vitis workspace called ``embeddedsw``.
   It copies the modified driver sources from the Git repo's ``EmbeddedSw`` folder to the local 
   software repository ``embeddedsw``. Then it copies the rest of the required sources from
   ``{Vitis Install Dir}\data\embeddedsw\``. The ``embeddedsw`` local software repository holds
   a modified version of the BSP libraries that are required by the application. For more
   information about the modifications to the libraries, see the README in the ``EmbeddedSw``
   folder of this Git repository.
#. Generates an empty application for each exported Vivado design
   that is found in the ``../Vivado`` directory. Most users will only have one exported
   Vivado design.
#. Copies the appropriate enumeration application source file from the
   ``\Vitis\common\src\`` directory of this repo into the application source directory.

Run the application
===================

#. Open Xilinx Vitis.
#. Power up your hardware platform and ensure that the JTAG is
   connected properly.
#. In the Vitis Explorer panel, double-click on the System project that you want to run -
   this will reveal the applications contained in the project. The System project will have 
   the postfix "_system".
#. Now click on the application that you want to run. It should have the postfix "_ssd_test_system".
#. Select the option "Run Configurations" from the drop-down menu contained under the Run
   button on the toolbar (play symbol).
#. Double-click on "Single Application Debug" to create a run configuration for this 
   application. Then click "Run".

The run configuration will first program the FPGA with the bitstream, then load and run the 
application. You can view the UART output of the application in a console window.

UART settings
=============

To receive the UART output of this standalone application, you will need to connect the
USB-UART of the development board to your PC and run a console program such as 
`Putty`_. The following UART settings must be used:

* Microblaze designs: 9600 baud
* Zynq and ZynqMP designs: 115200 baud

Linker script modifications for Zynq designs
--------------------------------------------

For the Zynq designs, the Vitis's linker script generator automatically assigns all sections
to the BAR0 memory space, instead of assigning them to the DDR memory space. This causes 
failure of the application to run, when booted from SD card or JTAG. To overcome this problem,
the Vitis build script modifies the generated linker script and correctly assigns the sections
to DDR memory.

If you want to manually create an application in the Vitis for one of the Zynq designs,
you will have to manually modify the automatically generated linker script, and set all sections
to DDR memory.

BSP Modifications
=================

axipcie
-------

This project uses a modified version of the axipcie driver.

The ``axipcie_v3_3`` driver is attached to designs that use the AXI Memory Mapped to PCIe IP (axi_pcie) and 
designs that use the AXI PCIe Gen3 IP (axi_pcie3). However, the driver contains a bug that affects designs
that use the AXI PCIe Gen3 IP.

The script ``axipcie_v3_3/data/acipcie.tcl`` generates the ``xparameters.h`` and ``xaxipcie_g.c`` BSP sources that
both contain a define called ``INCLUDE_RC``. To determine the value of this define, the script reads a parameter of 
the PCIe IP called ``CONFIG.INCLUDE_RC``, however this parameter only exists in the AXI Memory Mapped to PCIe IP.
Our modified version of the script uses the correct parameter to determine the value of ``INCLUDE_RC``.
Specifically, it reads the ``CONFIG.device_port_type`` parameter and compares it to the value that is expected
for root complex designs: ``Root_Port_of_PCI_Express_Root_Complex``.



.. _Putty: https://www.putty.org

