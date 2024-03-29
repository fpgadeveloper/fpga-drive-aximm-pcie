# Supported carrier boards

## List of supported boards

| Carrier board                                                    | FMC Slot |
|------------------------------------------------------------------|------|
| Zynq-7000 [PicoZed FMC Carrier Card V2] with [PicoZed 7030]      | LPC  |
| Kintex-7 [KC705 Evaluation board]                                | LPC & HPC |
| Virtex-7 [VC707 Evaluation board]                                | HPC1 & HPC2 |
| Virtex-7 [VC709 Evaluation board]                                | HPC  |
| Zynq-7000 [ZC706 Evaluation board]                               | LPC & HPC |
| Kintex UltraScale [KCU105 Evaluation board]                      | LPC & HPC |
| Virtex UltraScale+ [VCU118 Evaluation board]                     | FMCP |
| Zynq UltraScale+ [ZCU104 Evaluation board]                       | LPC  |
| Zynq UltraScale+ [ZCU106 Evaluation board]                       | HPC0 & HPC1 |
| Zynq UltraScale+ [ZCU111 Evaluation board]                       | FMC+ |
| Zynq UltraScale+ [ZCU208 Evaluation board]                       | FMC+ |
| Zynq UltraScale+ [UltraZed EV Carrier Card]                      | HPC  |
| Versal AI Core [VCK190 Evaluation board]                         | FMCP1 & FMCP2 |
| Versal Prime [VMK180 Evaluation board]                           | FMCP1 & FMCP2 |

For list of the target designs showing the number of SSDs supported, refer to the build instructions.

## Unlisted boards

If you need more information on whether the [FPGA Drive FMC] is compatible with a carrier that is not listed above, please first check the
[compatibility list]. If the carrier is not listed there, please [contact Opsero],
provide us with the pinout of your carrier and we'll be happy to check compatibility and generate a Vivado constraints file for you.

## Board specific notes

### KC705

* These designs use the AXI EthernetLite IP for their onboard Ethernet ports. This IP does not require a license, but 
  limits the link speed to 100Mbps.

### KCU105, VC707, VC709

* The on-board Ethernet port for these boards is not connected in these designs because they are not supported by
  the free AXI EthernetLite IP. The block design build script (`Vivado/src/bd/bd_mb.tcl`) contains the code to add 
  the AXI Ethernet IP for these boards and can be uncommented if Ethernet is required.

### PicoZed FMC Carrier Card V2

On this carrier, the GBTCLK0 of the LPC FMC connector is routed to a clock synthesizer/MUX, rather than being directly
connected to the Zynq. In order to use the FPGA Drive FMC on the [PicoZed FMC Carrier Card V2], 
you will need to reconfigure the clock synthesizer so that it feeds the FMC clock through to the Zynq. To change the configuration,
you must reprogram the EEPROM (U14) where the configuration is stored. Avnet provides an SD card boot file that can be run to
reprogram the EEPROM to the configuration we need for this project. The boot files have been copied to the links below for your
convenience:

* [PicoZed 7015 BOOT.bin for FMC clock config](https://download.opsero.com/picozed/pz_7015_fmc_clock.zip)
* [PicoZed 7030 BOOT.bin for FMC clock config](https://download.opsero.com/picozed/pz_7030_fmc_clock.zip)

Just boot up your [PicoZed FMC Carrier Card V2]
using one of those boot files, and the EEPROM will be reprogrammed as required for this project. For more information,
see the [PicoZed Hardware User Guide] for the [PicoZed FMC Carrier Card V2].

### ZCU106

The ZCU106 has two HPC FMC connectors, HPC0 and HPC1. The HPC0 connector has enough connected gigabit transceivers to support
2x SSDs, each with an independent 4-lane PCIe interface. The HPC1 connector has only 1x connected gigabit transceiver, so it can only
support 1x SSD (SSD1) with a 1-lane PCIe interface. This project contains designs for both of these connectors.

### ZCU111

The ZCU111 has a single FMC+ connector that can support 2x SSDs, each with an independent 4-lane PCIe interface.

### ZCU208

The ZCU208 has a single FMC+ connector that can support 2x SSDs, each with an independent 4-lane PCIe interface.

### VCK190 and VMK180

The VCK190 and VMK180 have two FMC+ connectors that both can support 2x SSDs with independent 4-lane PCIe interfaces.
These boards have a system controller that runs on a Zynq UltraScale+. The system controller is responsible for enabling
the adjustable voltage (VADJ) that is applied to the FMC cards. These designs can be run even when VADJ is not enabled
(ie. when VADJ=0V); they can be run without the system controller.

Note that the BEAM Tool 2.2 has a 
[known issue that causes multiple resets on power up](https://support.xilinx.com/s/article/000034111?language=en_US).
We recommend that you apply the fix if you intend to use this version of the BEAM tool.


[contact Opsero]: https://opsero.com/contact-us
[compatibility list]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/compatibility/
[FPGA Drive FMC]: https://fpgadrive.com
[PicoZed FMC Carrier Card V2]: http://zedboard.org/product/picozed-fmc-carrier-card-v2
[PicoZed 7030]: http://picozed.org
[UltraZed EV Carrier Card]: https://www.xilinx.com/products/boards-and-kits/1-y3n9v1.html
[ZC706 Evaluation board]: https://www.xilinx.com/zc706
[ZCU104 Evaluation board]: https://www.xilinx.com/zcu104
[ZCU106 Evaluation board]: https://www.xilinx.com/zcu106
[ZCU111 Evaluation board]: https://www.xilinx.com/zcu111
[ZCU208 Evaluation board]: https://www.xilinx.com/zcu208
[KC705 Evaluation board]: https://www.xilinx.com/kc705
[KCU105 Evaluation board]: https://www.xilinx.com/kcu105
[VC707 Evaluation board]: https://www.xilinx.com/vc707
[VC709 Evaluation board]: https://www.xilinx.com/vc709
[PicoZed Hardware User Guide]: https://www.element14.com/community/servlet/JiveServlet/downloadBody/90974-102-2-394635/5279-UG-PicoZed-7015-7030-V2_1.pdf
[VCK190 Evaluation board]: https://www.xilinx.com/vck190
[VMK180 Evaluation board]: https://www.xilinx.com/vmk180
[VCU118 Evaluation board]: https://www.xilinx.com/vcu118

