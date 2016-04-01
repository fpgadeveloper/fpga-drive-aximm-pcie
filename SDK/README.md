SDK Project files
=================

How to make use of these files
------------------------------

In order to make use of these source files, you must first generate
the Vivado project hardware design (the bitstream) and export the design
to SDK. Check the Vivado folder for instructions on doing this from Vivado.

Once the bitstream is generated and exported to SDK, then use the "Launch
SDK" option from Vivado, and select this folder (SDK) as the workspace
folder. By using this option, the hardware platform will be automatically
created in the SDK workspace and you wont have to do it yourself.

Import the application and BSP
------------------------------

1. Select File->Import.
2. In the Import window, select General->Existing projects into
workspace. Click Next.
3. Click Browse, and select this folder (the folder where this
readme file is located).
4. Ensure that both the application and BSP are ticked, then click
Finish.

Build your application
----------------------

You might have to right click on the BSP and use the Rebuild
BSP Libraries option.

Before trying to run your code, wait a while for SDK to build the
application. It should be automatic, but if it doesn't start by
itself, you can always select Project->Build All. It can sometimes
take a while, check the progress at the bottom right corner of the
SDK window.

Run the application
-------------------

1. Power up your hardware platform and ensure that the JTAG is
connected properly.
2. Select Xilinx Tools->Program FPGA. You only have to do this
once, each time you power up your hardware platform.
3. Select Run->Run to run your application. You can modify the code
and click Run as many times as you like, without going through
the other steps.


Jeff Johnson
http://www.fpgadeveloper.com
