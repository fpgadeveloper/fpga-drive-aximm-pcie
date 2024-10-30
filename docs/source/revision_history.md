# Revision History

## 2022.1 Changes

* Added Makefiles to improve the build experience for Linux users
* Consolidated Vivado batch files (user is prompted to select target design)
* Vitis build script now creates a separate workspace for each target design (improved user experience)
* Converted documentation to markdown (from reStructuredText)
* Removed the unnecessary postfix "pcie" from all designs

## 2024.1 Changes

* Removed PetaLinux support for pure FPGA platforms (eg. KC705)
* Added designs for:
  - Versal boards VEK280, VHK158, VCK120, VCK180
  - Zynq RFSoC boards: ZCU216
* Improved documentation, centralized targed design info to JSON file
* Removed single slot designs for platforms that can support two slots
* Removed "dual" postfix from dual designs
