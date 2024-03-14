FPGA Drive FMC Reference Designs
================================

## 2023.2 DEV BRANCH

This is a development branch for the purposes of updating the designs to version 2023.2 of the tools.
Not all designs should be considered stable.

## Description

This repo contains the example designs for the FPGA Drive FMC mated with several FPGA and MPSoC evaluation boards.

![FPGA Drive FMC top side](docs/source/images/fpga-drive-fmc.jpg "FPGA Drive FMC")

Important links:

* Datasheet for the [FPGA Drive FMC Gen4](https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/ "FPGA Drive FMC Gen4 Datasheet")
* The user guide for these reference designs is hosted here: [Ref design for FPGA Drive FMC docs](https://refdesign.fpgadrive.com "Ref design for FPGA Drive FMC docs")
* To report a bug: [Report an issue](https://github.com/fpgadeveloper/fpga-drive-aximm-pcie/issues "Report an issue").
* For technical support: [Contact Opsero](https://opsero.com/contact-us "Contact Opsero").
* To purchase the mezzanine card: [FPGA Drive FMC order page](https://opsero.com/product/fpga-drive-fmc-gen4/ "FPGA Drive FMC order page").

## Requirements

This project is designed for version 2023.2 of the Xilinx tools (Vivado/Vitis/PetaLinux). 
If you are using an older version of the Xilinx tools, then refer to the 
[release tags](https://github.com/fpgadeveloper/fpga-drive-aximm-pcie/tags "releases")
to find the version of this repository that matches your version of the tools.

In order to test this design on hardware, you will need the following:

* Vivado 2023.2
* Vitis 2023.2
* PetaLinux Tools 2023.2
* [FPGA Drive FMC Gen4](http://fpgadrive.com "FPGA Drive FMC Gen4") - for connecting a PCIe SSD
* M.2 PCIe Solid State Drive
* One of the supported carriers listed [here](https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/compatibility/)

## Build instructions

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

