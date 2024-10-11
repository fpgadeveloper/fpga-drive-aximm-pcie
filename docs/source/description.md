# Description

These are the example designs for the FPGA Drive FMC adapter that allows connecting
NVMe SSDs to FPGAs via the FPGA Mezzanine Card (FMC) connector.

![FPGA Drive FMC top side](images/fpga-drive-fmc.jpg)
    
The bare metal software application reports on the status of the PCIe link and 
performs enumeration of the detected PCIe end-points (ie. the SSDs). The project also contains
scripts to generate PetaLinux for these platforms to allow accessing the SSDs from the Linux
operating system.

## PCIe IP

These designs implement a PCIe root complex to interface with the SSDs. All designs make use of the integrated
PCIe blocks that are built into the FPGA or MPSoC device. The IP core that is used to exploit the integrated PCIe
block depends on the device.

| PCIe IP Core | Dev boards       |
|---------------------------------------------------------------------------------------------------------------------------|------------------|
| [AXI Memory Mapped to PCI Express (PCIe) Gen 2 IP](https://www.xilinx.com/products/intellectual-property/axi_pcie.html)   | [KC705], [VC707], PicoZed, [ZC706] |
| [AXI PCI Express (PCIe) Gen 3 Subsystem IP](https://www.xilinx.com/products/intellectual-property/axi_pcie_gen3.html)     | [VC709], [KCU105]    |
| [DMA for PCI Express (PCIe) Subsystem IP](https://www.xilinx.com/products/intellectual-property/pcie-dma.html)            | [ZCU104], [ZCU106], [ZCU111], [ZCU208], UltraZed EV |
| [QDMA Subsystem for PCI Express (PCIe) IP](https://docs.xilinx.com/r/en-US/pg302-qdma) | [VCK190], [VMK180] |

## Single SSD designs

![FPGA Drive FMC with single SSD loaded](images/fpga-drive-fmc-single-load.jpg)
    
The target designs that are intended to be used with only one SSD should be loaded as
shown in the above image. The SSD should be loaded into the first M.2 slot, labelled SSD1. If you are using 
the older version FPGA Drive FMC (Rev-B) with only one M.2 connector, you will only be able to use the single SSD designs.

## Dual SSD designs

![FPGA Drive FMC with two SSDs loaded](images/fpga-drive-fmc-dual-load.jpg)

The target designs that are intended to be used with two SSDs can be loaded as shown
in the above image.


[AC701]: https://www.xilinx.com/ac701
[KC705]: https://www.xilinx.com/kc705
[VC707]: https://www.xilinx.com/vc707
[VC709]: https://www.xilinx.com/vc709
[VCK190]: https://www.xilinx.com/vck190
[VMK180]: https://www.xilinx.com/vmk180
[VCU108]: https://www.xilinx.com/vcu108
[VCU118]: https://www.xilinx.com/vcu118
[KCU105]: https://www.xilinx.com/kcu105
[ZC702]: https://www.xilinx.com/zc702
[ZC706]: https://www.xilinx.com/zc706
[ZCU111]: https://www.xilinx.com/zcu111
[ZCU208]: https://www.xilinx.com/zcu208
[ZCU104]: https://www.xilinx.com/zcu104
[ZCU102]: https://www.xilinx.com/zcu102
[ZCU106]: https://www.xilinx.com/zcu106

