# FPGA Drive FMC Reference Designs

## Description

This repo contains the example designs for the Opsero [FPGA Drive FMC Gen4] and Opsero [M.2 M-key Stack FMC] 
mated with several FPGA and MPSoC evaluation boards.

| FPGA Drive FMC Gen4 | M.2 M-key Stack FMC |
|---------------------|---------------------|
| ![FPGA Drive FMC Gen4](docs/source/images/fpga-drive-fmc-gen4.png "FPGA Drive FMC Gen4") | ![M.2 M-key Stack FMC](docs/source/images/m2-mkey-stack-fmc.png "M.2 M-key Stack FMC") |

Important links:

* Datasheet for the [FPGA Drive FMC Gen4]
* Datasheet for the [M.2 M-key Stack FMC]
* The user guide for these reference designs is hosted here: [Ref design for FPGA Drive FMC docs](https://refdesign.fpgadrive.com "Ref design for FPGA Drive FMC docs")
* To report a bug: [Report an issue](https://github.com/fpgadeveloper/fpga-drive-aximm-pcie/issues "Report an issue").
* For technical support: [Contact Opsero](https://opsero.com/contact-us "Contact Opsero").

## Requirements

This project is designed for version 2024.1 of the Xilinx tools (Vivado/Vitis/PetaLinux). 
If you are using an older version of the Xilinx tools, then refer to the 
[release tags](https://github.com/fpgadeveloper/fpga-drive-aximm-pcie/tags "releases")
to find the version of this repository that matches your version of the tools.

In order to test this design on hardware, you will need the following:

* Vivado 2024.1
* Vitis 2024.1
* PetaLinux Tools 2024.1
* [FPGA Drive FMC Gen4] or [M.2 M-key Stack FMC]
* M.2 NVMe PCIe Solid State Drive
* One of the supported carriers listed [here](https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/compatibility/)

## Target designs

This repo contains several designs that target various supported development boards and their
FMC connectors. The table below lists the target design name, the M2 ports supported by the design and 
the FMC connector on which to connect the FPGA Drive FMC Gen4. Some of the target designs
require a license to generate a bitstream with the AMD Xilinx tools.

<!-- updater start -->
### FPGA designs

| Target board          | Target design   | M2 Slot 1<br> PCIe Lanes | M2 Slot 2<br> PCIe Lanes | FMC Slot    | License<br> required |
|-----------------------|-----------------|--------------------------|--------------------------|-------------|-------|
| [KC705]               | `kc705_hpc`     | 4                        | -                        | HPC         | YES   |
| [KC705]               | `kc705_lpc`     | 1                        | -                        | LPC         | YES   |
| [KCU105]              | `kcu105_hpc`    | 4                        | 4                        | HPC         | YES   |
| [KCU105]              | `kcu105_lpc`    | 1                        | -                        | LPC         | YES   |
| [VC707]               | `vc707_hpc1`    | 4                        | -                        | HPC1        | YES   |
| [VC707]               | `vc707_hpc2`    | 4                        | -                        | HPC2        | YES   |
| [VC709]               | `vc709_hpc`     | 4                        | -                        | HPC         | YES   |
| [VCU118]              | `vcu118`        | 4                        | 4                        | FMCP        | YES   |

### Zynq-7000 designs

| Target board          | Target design   | M2 Slot 1<br> PCIe Lanes | M2 Slot 2<br> PCIe Lanes | FMC Slot    | License<br> required |
|-----------------------|-----------------|--------------------------|--------------------------|-------------|-------|
| [PicoZed 7015]        | `pz_7015`       | 1                        | -                        | LPC         | NO    |
| [PicoZed 7030]        | `pz_7030`       | 1                        | -                        | LPC         | NO    |
| [ZC706]               | `zc706_hpc`     | 4                        | -                        | HPC         | YES   |
| [ZC706]               | `zc706_lpc`     | 1                        | -                        | LPC         | YES   |

### Zynq UltraScale+ designs

| Target board          | Target design   | M2 Slot 1<br> PCIe Lanes | M2 Slot 2<br> PCIe Lanes | FMC Slot    | License<br> required |
|-----------------------|-----------------|--------------------------|--------------------------|-------------|-------|
| [UltraZed-EV Carrier] | `uzev`          | 4                        | 4                        | HPC         | NO    |
| [ZCU104]              | `zcu104`        | 1                        | -                        | LPC         | NO    |
| [ZCU106]              | `zcu106_hpc0`   | 4                        | 4                        | HPC0        | NO    |
| [ZCU106]              | `zcu106_hpc1`   | 1                        | -                        | HPC1        | NO    |
| [ZCU111]              | `zcu111`        | 4                        | 4                        | FMCP        | YES   |
| [ZCU208]              | `zcu208`        | 4                        | 4                        | FMCP        | YES   |
| [ZCU216]              | `zcu216`        | 4                        | 4                        | FMCP        | YES   |

### Versal designs

| Target board          | Target design   | M2 Slot 1<br> PCIe Lanes | M2 Slot 2<br> PCIe Lanes | FMC Slot    | License<br> required |
|-----------------------|-----------------|--------------------------|--------------------------|-------------|-------|
| [VCK190]              | `vck190_fmcp1`  | 4                        | 4                        | FMCP1       | YES   |
| [VCK190]              | `vck190_fmcp2`  | 4                        | 4                        | FMCP2       | YES   |
| [VHK158]              | `vhk158`        | 4                        | -                        | FMCP        | YES   |
| [VMK180]              | `vmk180_fmcp1`  | 4                        | 4                        | FMCP1       | YES   |
| [VMK180]              | `vmk180_fmcp2`  | 4                        | 4                        | FMCP2       | YES   |
| [VEK280]              | `vek280`        | 4                        | 4                        | FMCP        | YES   |
| [VPK120]              | `vpk120`        | 4                        | -                        | FMCP        | YES   |
| [VPK180]              | `vpk180`        | 4                        | -                        | FMCP        | YES   |

[KC705]: https://www.xilinx.com/kc705
[KCU105]: https://www.xilinx.com/kcu105
[VC707]: https://www.xilinx.com/vc707
[VC709]: https://www.xilinx.com/vc709
[VCU118]: https://www.xilinx.com/vcu118
[PicoZed 7015]: https://www.xilinx.com/products/boards-and-kits/1-hypn9d.html
[PicoZed 7030]: https://www.xilinx.com/products/boards-and-kits/1-hypn9d.html
[ZC706]: https://www.xilinx.com/zc706
[UltraZed-EV Carrier]: https://www.xilinx.com/products/boards-and-kits/1-1s78dxb.html
[ZCU104]: https://www.xilinx.com/zcu104
[ZCU106]: https://www.xilinx.com/zcu106
[ZCU111]: https://www.xilinx.com/zcu111
[ZCU208]: https://www.xilinx.com/zcu208
[ZCU216]: https://www.xilinx.com/zcu216
[VCK190]: https://www.xilinx.com/vck190
[VHK158]: https://www.xilinx.com/vhk158
[VMK180]: https://www.xilinx.com/vmk180
[VEK280]: https://www.xilinx.com/vek280
[VPK120]: https://www.xilinx.com/vpk120
[VPK180]: https://www.xilinx.com/vpk180
<!-- updater end -->

Notes:

1. The [VPK120] and [VPK180] have enough GTs to interface with both SSDs, however they have only 2 integrated PCIe blocks
   one of which is on the opposite side of the device to the GT quads, making routing a challenge.
   For this reason the [VPK120] and [VPK180] designs supports only 1x SSD.

## Software

These reference designs can be driven by either a standalone application or within a PetaLinux environment. 
The repository includes all necessary scripts and code to build both environments. The table 
below outlines the corresponding applications available in each environment:

| Environment      | Available Applications  |
|------------------|-------------------------|
| Standalone       | PCIe enumeration test |
| PetaLinux        | Built-in Linux commands<br>Additional tools: mke2fs, badblocks, mount, mkfs, blkid, fdisk, pciutils |

The standalone software application reports on the status of the PCIe link and 
performs enumeration of the detected PCIe end-points (ie. the M.2 modules).

## Build instructions

Clone the repo:
```
git clone https://github.com/fpgadeveloper/fpga-drive-aximm-pcie.git
```

Source Vivado and PetaLinux tools:

```
source <path-to-petalinux>/2024.1/settings.sh
source <path-to-vivado>/2024.1/settings64.sh
```

To build the standalone PCIe enumeration test application (Vivado project and Vitis workspace):

```
cd fpga-drive-aximm-pcie/Vitis
make workspace TARGET=uzev
```

Build all (Vivado project and PetaLinux):

```
cd fpga-drive-aximm-pcie/PetaLinux
make petalinux TARGET=uzev
```

More comprehensive build instructions can be found in the user guide:
* [For Windows users](https://refdesign.fpgadrive.com/en/latest/build_instructions.html#windows-users)
* [For Linux users](https://refdesign.fpgadrive.com/en/latest/build_instructions.html#linux-users)

## Contribute

We strongly encourage community contribution to these projects. Please make a pull request if you
would like to share your work:
* if you've spotted and fixed any issues
* if you've added designs for other target platforms
* if you've added software support for other devices

Thank you to everyone who supports us!

## About us

[Opsero Inc.](https://opsero.com "Opsero Inc.") is a team of FPGA developers delivering FPGA products and 
design services to start-ups and tech companies. Follow our blog, 
[FPGA Developer](https://www.fpgadeveloper.com "FPGA Developer"), for news, tutorials and
updates on the awesome projects we work on.

[FPGA Drive FMC Gen4]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/
[M.2 M-key Stack FMC]: https://www.fpgadrive.com/docs/m2-mkey-stack-fmc/overview/

