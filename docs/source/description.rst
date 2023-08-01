============
Description
============

These are the example designs for the FPGA Drive FMC adapter that allows connecting
NVMe SSDs to FPGAs via the FPGA Mezzanine Card (FMC) connector.

.. figure:: images/fpga-drive-fmc.jpg
    :align: center
    :name: fpga-drive-fmc
    
    FPGA Drive FMC top side
    
The bare metal software application reports on the status of the PCIe link and 
performs enumeration of the detected PCIe end-points (ie. the SSDs). The project also contains
scripts to generate PetaLinux for these platforms to allow accessing the SSDs from the Linux
operating system.

PCIe IP
=======

These designs implement a PCIe root complex to interface with the SSDs. All designs make use of the integrated
PCIe blocks that are built into the FPGA or MPSoC device. The IP core that is used to exploit the integrated PCIe
block depends on the device.

+-----------------------------------------------------------------------------------------------------------------------------------------+------------------+
| PCIe IP Core                                                                                                                            | Dev board        |
+=========================================================================================================================================+==================+
| `AXI Memory Mapped to PCI Express (PCIe) Gen 2 IP <https://www.xilinx.com/products/intellectual-property/axi_pcie.html>`_               | | KC705          |
|                                                                                                                                         | | VC707          |
|                                                                                                                                         | | PicoZed        |
|                                                                                                                                         | | ZC706          |
+-----------------------------------------------------------------------------------------------------------------------------------------+------------------+
| `AXI PCI Express (PCIe) Gen 3 Subsystem IP <https://www.xilinx.com/products/intellectual-property/axi_pcie_gen3.html>`_                 | | VC709          |
|                                                                                                                                         | | KCU105         |
+-----------------------------------------------------------------------------------------------------------------------------------------+------------------+
| `DMA for PCI Express (PCIe) Subsystem IP <https://www.xilinx.com/products/intellectual-property/pcie-dma.html>`_                        | | ZCU104         |
|                                                                                                                                         | | ZCU106         |
|                                                                                                                                         | | ZCU111         |
|                                                                                                                                         | | ZCU208         |
|                                                                                                                                         | | UltraZed EV    |
+-----------------------------------------------------------------------------------------------------------------------------------------+------------------+

Single SSD designs
==================

.. figure:: images/fpga-drive-fmc-single-load.jpg
    :align: center
    :name: fpga-drive-fmc-single-load
    
    FPGA Drive FMC with single SSD loaded
    
The projects in this repo without the "_dual" postfix are intended to be used with only one loaded SSD as
shown in the above image. The SSD should be loaded into the first M.2 slot, labelled SSD1. If you are using 
the older version FPGA Drive FMC (Rev-B) with only one M.2 connector, you will only be able to use the single SSD designs.

Dual SSD designs
================

.. figure:: images/fpga-drive-fmc-dual-load.jpg
    :align: center
    :name: fpga-drive-fmc-dual-load
    
    FPGA Drive FMC with two SSDs loaded

The projects in this repo with the "_dual" postfix are intended to be used with two loaded SSDs as shown
in the above image. The dual designs may not function as expected if only one SSD is loaded. If you are using the 
older version FPGA Drive FMC (Rev-B) with only one M.2 connector, you will not be able to use the dual designs.

At the moment there are dual designs for these carriers:

* KCU105
* ZCU106
* ZCU111
* ZCU208
* Avnet UltraZed-EV Starter Kit

