fpga-drive-aximm-pcie
=====================

Example design for FPGA Drive using the AXI Memory Mapped to PCI Express Bridge IP.

## Supported carrier boards

* Kintex-7 [KC705 Evaluation board](http://www.xilinx.com/products/boards-and-kits/ek-k7-kc705-g.html "KC705 Evaluation board")

### Future support

This repository contains designs for the following boards, however they should not be considered functional at this stage.
Please contact me for more information.

* [PicoZed 7Z030](http://zedboard.org/product/picozed "PicoZed") with [PicoZed FMC Carrier](http://zedboard.org/product/picozed-carrier-card "PicoZed FMC Carrier")

## Description

This project demonstrates using the AXI Memory Mapped to PCIe Bridge IP
to interface an FPGA with a PCIe end-point device. The bridge IP is configured
as a PCIe Root Port, using 1 to 4 lanes, Gen2.

The bare metal software application will enumerate the detected PCIe end-points
and then perform some reads and writes to a connected M.2 PCIe SSD. The SSD
connects to the FPGA via the FPGA Drive adapter.

## Requirements

In order to test this design on hardware, you will need the following:

* Vivado 2015.4
* [FPGA Drive](http://fpgadrive.com "FPGA Drive")
* M.2 PCIe Solid State Drive
* Supported FMC carrier board (see list of supported carriers above)

### Installation of PicoZed board definition files

To use this project on the PicoZed, you must first install the board definition files
for the PicoZed into your Vivado installation.

The following folders contain the board definition files and can be found in this project repository at this location:

https://github.com/fpgadeveloper/picozed-qgige-axieth/tree/master/Vivado/boards/board_files

* `picozed_7015`
* `picozed_7030`

Copy those folders and their contents into the `C:\Xilinx\Vivado\2015.4\data\boards\board_files` folder (this may
be different on your machine, depending on your Vivado installation directory).

## License

Feel free to modify the code for your specific application.

## Fork and share

If you port this project to another hardware platform, please send me the
code or push it onto GitHub and send me the link so I can post it on my
website. The more people that benefit, the better.

## About the author

I'm an FPGA consultant and I provide FPGA design services to innovative
companies around the world. I believe in sharing knowledge and
I regularly contribute to the open source community.

Jeff Johnson
[FPGA Developer](http://www.fpgadeveloper.com "FPGA Developer")