========================
Supported carrier boards
========================

List of supported boards
========================

+-----------------------------------------------------------------------+------+---------------------+ 
| Carrier board                                                         | FMC  | No. SSDs            |
+=======================================================================+======+=====================+ 
| | Zynq-7000 `PicoZed FMC Carrier Card V2`_                            | LPC  | Single SSD          |
| | with `PicoZed 7030`_                                                |      |                     |
+-----------------------------------------------------------------------+------+---------------------+ 
| Kintex-7 `KC705 Evaluation board`_                                    | LPC  | Single SSD          |
|                                                                       +------+---------------------+ 
|                                                                       | HPC  | Single SSD          |
+-----------------------------------------------------------------------+------+---------------------+ 
| Kintex UltraScale `KCU105 Evaluation board`_                          | LPC  | Single SSD          |
|                                                                       +------+---------------------+ 
|                                                                       | HPC  | Single & dual SSD   |
+-----------------------------------------------------------------------+------+---------------------+ 
| Virtex-7 `VC707 Evaluation board`_                                    | HPC1 | Single SSD          |
|                                                                       +------+---------------------+ 
|                                                                       | HPC2 | Single SSD          |
+-----------------------------------------------------------------------+------+---------------------+ 
| Virtex-7 `VC709 Evaluation board`_                                    | HPC  | Single SSD          |
+-----------------------------------------------------------------------+------+---------------------+ 
| Zynq-7000 `ZC706 Evaluation board`_                                   | LPC  | Single SSD          |
|                                                                       +------+---------------------+ 
|                                                                       | HPC  | Single SSD          |
+-----------------------------------------------------------------------+------+---------------------+ 
| Zynq UltraScale+ `ZCU104 Evaluation board`_                           | LPC  | Single SSD          |
+-----------------------------------------------------------------------+------+---------------------+ 
| Zynq UltraScale+ `ZCU106 Evaluation board`_                           | HPC0 | Single & dual SSD   |
|                                                                       +------+---------------------+ 
|                                                                       | HPC1 | Single SSD          |
+-----------------------------------------------------------------------+------+---------------------+ 
| Zynq UltraScale+ `ZCU111 Evaluation board`_                           | FMC+ | Single & dual SSD   |
+-----------------------------------------------------------------------+------+---------------------+ 
| Zynq UltraScale+ `UltraZed EV Carrier Card`_                          | HPC  | Dual SSD design     |
+-----------------------------------------------------------------------+------+---------------------+ 

Unlisted boards
===============

If you need more information on whether the `FPGA Drive FMC`_ is compatible with a carrier that is not listed above, please first check the
`compatibility list`_. If the carrier is not listed there, please `contact Opsero`_,
provide us with the pinout of your carrier and we'll be happy to check compatibility and generate a Vivado constraints file for you.

Board specific notes
====================

AC701 and KC705
---------------

* These designs use the AXI EthernetLite IP for their onboard Ethernet ports. This IP does not require a license, but 
  limits the link speed to 100Mbps.

KCU105, VC707, VC709
--------------------

* The on-board Ethernet port for these boards is not connected in these designs because they are not supported by
  the free AXI EthernetLite IP. The block design build script (design_1-mb.tcl) contains the code to add the AXI Ethernet IP
  for these boards and can be uncommented if Ethernet is desired.

KCU105
------

* This design uses the Quad SPI flash in dual mode with SPIx8 interface (64MB total storage).

PicoZed and UltraZed-EV
-----------------------

**Installation of board definition files**

To use this project on the PicoZed or UltraZed-EV, you must first install the board definition files
for these boards into your Vivado installation.

The following folders contain the board definition files and can be found in this project repository at this location:

https://github.com/fpgadeveloper/fpga-drive-aximm-pcie/tree/master/Vivado/boards/board_files

* ``picozed_7015_fmc2``
* ``picozed_7030_fmc2``
* ``ultrazed_7ev_cc``

Copy those folders and their contents into the ``C:\Xilinx\Vivado\2020.2\data\boards\board_files`` folder (this may
be different on your machine, depending on your Vivado installation directory).

PicoZed FMC Carrier Card V2
---------------------------

On this carrier, the GBTCLK0 of the LPC FMC connector is routed to a clock synthesizer/MUX, rather than being directly
connected to the Zynq. In order to use the FPGA Drive FMC on the `PicoZed FMC Carrier Card V2`_, 
you will need to reconfigure the clock synthesizer so that it feeds the FMC clock through to the Zynq. To change the configuration,
you must reprogram the EEPROM (U14) where the configuration is stored. Avnet provides an SD card boot file that can be run to
reprogram the EEPROM to the configuration we need for this project. The boot files have been copied to the links below for your
convenience:

* `PicoZed 7015 BOOT.bin for FMC clock config <https://download.opsero.com/picozed/pz_7015_fmc_clock.zip>`_
* `PicoZed 7030 BOOT.bin for FMC clock config <https://download.opsero.com/picozed/pz_7030_fmc_clock.zip>`_

Just boot up your `PicoZed FMC Carrier Card V2`_
using one of those boot files, and the EEPROM will be reprogrammed as required for this project. For more information,
see the `PicoZed Hardware User Guide`_ for the `PicoZed FMC Carrier Card V2`_.

ZCU106
------

The ZCU106 has two HPC FMC connectors, HPC0 and HPC1. The HPC0 connector has enough connected gigabit transceivers to support
2x SSDs, each with an independent 4-lane PCIe interface. The HPC1 connector has only 1x connected gigabit transceiver, so it can only
support 1x SSD (SSD1) with a 1-lane PCIe interface. This project contains designs for both of these connectors.

ZCU111
------

The ZCU111 has a single FMC+ connector that can support 2x SSDs, each with an independent 4-lane PCIe interface.




.. _contact Opsero: https://opsero.com/contact-us
.. _compatibility list: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/compatibility/
.. _FPGA Drive FMC: https://fpgadrive.com
.. _PicoZed FMC Carrier Card V2: http://zedboard.org/product/picozed-fmc-carrier-card-v2
.. _PicoZed 7030: http://picozed.org
.. _UltraZed EV Carrier Card: https://www.xilinx.com/products/boards-and-kits/1-y3n9v1.html
.. _ZC706 Evaluation board: https://www.xilinx.com/zc706
.. _ZCU104 Evaluation board: https://www.xilinx.com/zcu104
.. _ZCU106 Evaluation board: https://www.xilinx.com/zcu106
.. _ZCU111 Evaluation board: https://www.xilinx.com/zcu111
.. _KC705 Evaluation board: https://www.xilinx.com/kc705
.. _KCU105 Evaluation board: https://www.xilinx.com/kcu105
.. _VC707 Evaluation board: https://www.xilinx.com/vc707
.. _VC709 Evaluation board: https://www.xilinx.com/vc709
.. _PicoZed Hardware User Guide: https://www.element14.com/community/servlet/JiveServlet/downloadBody/90974-102-2-394635/5279-UG-PicoZed-7015-7030-V2_1.pdf