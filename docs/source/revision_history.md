# Revision History

## 2025.2 Changes

* Added a Yocto / EDF build flow (`Yocto/`) — AMD's Embedded Development
  Framework, the successor to PetaLinux — driven by a single
  `make yocto TARGET=<board>` command via the `gen-machineconf parse-sdt`
  flow, covering the Zynq-7000, Zynq UltraScale+ and Versal targets. The
  PetaLinux flow for this repository will be retired after 2025.2.
* Bumped Vivado, Vitis and PetaLinux requirement to 2025.2
* Migrated Vitis flow to the universal Python build driver
  (`Vitis/py/build-vitis.py` + `args.json`)
* Switched to System Device Tree (SDT) BSP generation; updated source
  examples for SDT compatibility (axipcie / xdmapcie drivers)
* Vendored modified `axipcie_v3_4` and `xdmapcie_v3_1` drivers under
  `EmbeddedSw/` to fix SDT compatible-string mapping and Versal QDMA
  address-swap behaviour (see [stand_alone](stand_alone) for details)
* Verified the previously documented "Slave Illegal Burst" Vivado 2024.1
  issue no longer reproduces with the current 2025.2 Versal designs;
  removed the AR000036860 tactical-patch workaround note
* Added per-BSP U-Boot device-tree overlay
  (`meta-xilinx-tools/recipes-bsp/uboot-device-tree/`) for every
  target so U-Boot sees the FMC-side PCIe bridge

## 2024.1 Changes

* Removed PetaLinux support for pure FPGA platforms (eg. KC705)
* Added designs for:
  - Versal boards VEK280, VHK158, VCK120, VCK180
  - Zynq RFSoC boards: ZCU216
* Improved documentation, centralized targed design info to JSON file
* Removed single slot designs for platforms that can support two slots
* Removed "dual" postfix from dual designs

## 2022.1 Changes

* Added Makefiles to improve the build experience for Linux users
* Consolidated Vivado batch files (user is prompted to select target design)
* Vitis build script now creates a separate workspace for each target design (improved user experience)
* Converted documentation to markdown (from reStructuredText)
* Removed the unnecessary postfix "pcie" from all designs
