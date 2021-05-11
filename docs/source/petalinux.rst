=========
PetaLinux
=========

PetaLinux can be built for these reference designs by using the script in the ``PetaLinux`` directory
of the repository.

How to build
============

Requirements
------------

* Windows or Linux PC with Vivado installed
* Linux PC or virtual machine with PetaLinux installed

Instructions
------------

1. First generate the Vivado project hardware design(s) (the bitstream) and export the design(s).
2. Launch PetaLinux by sourcing the ``settings.sh`` bash script, eg: ``source <path-to-installed-petalinux>/settings.sh``
3. Build the PetaLinux project(s) by executing the ``build-petalinux`` script in Linux.

The script will generate a separate PetaLinux project for all of the generated and exported Vivado projects that
it finds in the Vivado directory of this repo.

UNIX line endings
=================

The scripts and files in the PetaLinux directory of this repository must have UNIX line endings when they are
executed or used under Linux. The best way to ensure UNIX line endings, is to clone the repo directly onto your
Linux machine. If instead you have copied the repo from a Windows machine, the files will have DOS line endings and
you must use the ``dos2unix`` tool to convert the line endings for UNIX.

#. Copy the cloned repository from your Windows machine to your Linux machine.
#. Use the ``cd`` command to navigate to the copied repository on your Linux machine.
#. Type ``find . -type f -exec dos2unix --keepdate {} +`` to convert all of the files
   to the Unix format.

How the script works
====================

The PetaLinux directory contains a ``build-petalinux`` shell script which can be run in Linux to automatically
generate a PetaLinux project for each of the generated/exported Vivado projects in the Vivado directory.

When executed, the build script searches the Vivado directory for all projects containing a ``.xsa`` exported
hardware design file. Then for every exported project, the script does the following:

#. Verifies that the ``.bit`` file exists.
#. Determines the CPU type: Microblaze, Zynq or ZynqMP. It does this
   by reading the Vivado project file.
#. Creates a PetaLinux project, referencing the exported hardware design (.xsa).
#. Copies the relevant configuration files from the ``src`` directory into the created
   PetaLinux project.
#. Builds the PetaLinux project.
#. Generates a BOOT.BIN, boot.scr and image.ub file for the Zynq and ZynqMP projects.

Launch PetaLinux on hardware
============================

Via JTAG
--------

To launch the PetaLinux project on hardware via JTAG, connect and power up your hardware and then
use the following commands in a Linux command terminal:

#. Change current directory to the PetaLinux project directory:
   ``cd <petalinux-project-dir>``
#. Download bitstream to the FPGA:
   ``petalinux-boot --jtag --fpga``
   Note that you don't have to specify the bitstream because this command will use the one that it finds
   in the ``./images/linux`` directory.
#. Download the PetaLinux kernel to the FPGA:
   ``petalinux-boot --jtag --kernel``

Via SD card
-----------

To launch the PetaLinux project on hardware via SD card, copy the following files to the root of the
SD card:

* ``/<petalinux-project>/images/linux/BOOT.bin``
* ``/<petalinux-project>/images/linux/boot.scr``
* ``/<petalinux-project>/images/linux/image.ub``

Then connect and power your hardware.

Setup the NVMe SSD in PetaLinux
===============================

#. Log into PetaLinux using the username ``root`` and the password ``root``.
#. Check that the SSD has been enumerated using: ``lspci``. Without any arguments, you get the output as shown 
   in the image below. Use the ``-vv`` argument, to get a more detailed output with the link speed, number of
   lanes used, etc.   

   .. figure:: images/setup_ssd_in_petalinux_1.png
       :align: center
       :name: setup_ssd_in_petalinux_1
       
       Check that the SSD has been enumerated with lspci

#. Use lsblk to make sure that the SSD has been recognized as a block device: 
   ``lsblk``.

   .. figure:: images/setup_ssd_in_petalinux_2.png
       :align: center
       :name: setup_ssd_in_petalinux_2
       
       Running lsblk

#. Run fdisk to create a partition on the SSD: ``fdisk /dev/nvme0n1``.

   .. figure:: images/setup_ssd_in_petalinux_3.png
       :align: center
       :name: setup_ssd_in_petalinux_3
       
       Running fdisk
   
#. Type these options in fdisk:

    - Type ``n`` to create a new partition
    - Then type ``p``, then ``1`` to create a new primary partition
    - Use the defaults for the sector numbers
    - Then type ``w`` to write the data to the disk

   .. figure:: images/setup_ssd_in_petalinux_4.png
       :align: center
       :name: setup_ssd_in_petalinux_4
       
       Using fdisk to create a partition

#. Get the name of the partition created by running ``lsblk`` again. In the example below, it is ``nvme0n1p1``.

   .. figure:: images/setup_ssd_in_petalinux_5.png
       :align: center
       :name: setup_ssd_in_petalinux_5
       
       Get the partition name with lsblk

#. Create a file system on the new partition using: ``mkfs -t ext2 /dev/nvme0n1p1``.

   .. figure:: images/setup_ssd_in_petalinux_6.png
       :align: center
       :name: setup_ssd_in_petalinux_6
       
       Create the file system using mkfs

#. Make a directory to mount the file system to using: ``mkdir /media/nvme``.
#. Mount the SSD to that directory: ``mount /dev/nvme0n1p1 /media/nvme``.

   .. figure:: images/setup_ssd_in_petalinux_7.png
       :align: center
       :name: setup_ssd_in_petalinux_7
       
       Make a directory for the SSD and mount it


From this point you will be able to access the SSD from the Linux command line.
The SSD will be mounted to the directory ``/media/nvme``. You should be able to copy files to 
that directory, create new files, delete files and use all the disk tools that are available in
the PetaLinux build.


Kernel Start Address for AXI PCIe Gen3 Subsystem
================================================

The AXI PCIe Gen3 Subsystem requires it's CTL0 interface to be allocated 256MB on the address map.
During Linux boot, vmalloc is used to allocate virtual memory for this interface. This repo configures
the Kernel start address to 0xB0000000 from the default 0xC0000000, in order to create sufficient
virtual memory for the CTL0 interface. Without this modification, vmalloc fails during boot.

Find the modification here:

``PetaLinux/src/axi_pcie3/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/kernel-options.cfg``

Known Issues
============

KCU105 Dual design fails to boot when one or both SSDs are not connected
------------------------------------------------------------------------

In the case where only one or neither SSD is connected, the PetaLinux boot freezes during the PCIe
enumeration. For example, if we connect SSD1 but not SSD2, PetaLinux boot stops after the following
lines:

.. code-block::

   xilinx-pcie 10000000.axi-pcie: PCIe Link is UP
   xilinx-pcie 10000000.axi-pcie: host bridge /amba_pl/axi-pcie@10000000 ranges:
   xilinx-pcie 10000000.axi-pcie:   MEM 0x60000000..0x6fffffff -> 0x60000000
   xilinx-pcie 10000000.axi-pcie: PCI host bridge to bus 0000:00
   pci_bus 0000:00: root bus resource [bus 00-ff]
   pci_bus 0000:00: root bus resource [mem 0x60000000-0x6fffffff]
   pci 0000:00:00.0: [10ee:8134] type 01 class 0x060400
   pci 0000:00:00.0: reg 0x38: [mem 0x00000000-0x000007ff pref]
   pci 0000:00:00.0: bridge configuration invalid ([bus 00-00]), reconfiguring
   pci 0000:01:00.0: [144d:a808] type 00 class 0x010802
   pci 0000:01:00.0: reg 0x10: [mem 0x00000000-0x00003fff 64bit]
   pci_bus 0000:01: busn_res: [bus 01-ff] end is updated to 01
   pci 0000:00:00.0: BAR 8: assigned [mem 0x60000000-0x600fffff]
   pci 0000:00:00.0: BAR 6: assigned [mem 0x60100000-0x601007ff pref]
   pci 0000:01:00.0: BAR 0: assigned [mem 0x60000000-0x60003fff 64bit]
   pci 0000:00:00.0: PCI bridge to [bus 01]
   pci 0000:00:00.0:   bridge window [mem 0x60000000-0x600fffff]
   xilinx-pcie 20000000.axi-pcie: PCIe Link is DOWN
   xilinx-pcie 20000000.axi-pcie: host bridge /amba_pl/axi-pcie@20000000 ranges:
   xilinx-pcie 20000000.axi-pcie:   MEM 0x70000000..0x7fffffff -> 0x70000000
   xilinx-pcie 20000000.axi-pcie: PCI host bridge to bus 0001:00
   pci_bus 0001:00: root bus resource [bus 00-ff]
   pci_bus 0001:00: root bus resource [mem 0x70000000-0x7fffffff]
   pci 0001:00:00.0: [10ee:8134] type 01 class 0x060400

We suspect that this is caused by a mishandling of the "PCIe Link is DOWN" case by the AXI PCIe
driver. The correct behavior should be that the enumeration is skipped and boot continues when the
down link is detected.

It is worth noting that our ZCU102 Dual design does NOT fail to boot under these conditions,
suggesting that the XDMA driver IS designed to properly handle the "PCIe Link is DOWN" case.
We are still looking for a solution to this issue.
