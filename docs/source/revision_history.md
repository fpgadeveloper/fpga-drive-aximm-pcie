# Revision History

## 2025.2 Changes

* Added a Yocto / EDF build flow (`Yocto/`) — AMD's Embedded Development
  Framework, the successor to PetaLinux — driven by a single
  `./build.sh yocto --target <board>` command via the `gen-machineconf parse-sdt`
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
* Fixed the baremetal application aborting with "AXI PCIe is configured as
  endpoint" on the AXI PCIe Gen2 designs (kc705, vc707, zc706, PicoZed):
  the Gen2 IP publishes the root-port flag as `xlnx,port-type` while the
  Gen3 IP publishes it as `xlnx,dev-port-type`, so the axipcie driver YAML
  is now matched to the PCIe IP in the design (issue #41)
* Verified the previously documented "Slave Illegal Burst" Vivado 2024.1
  issue no longer reproduces with the current 2025.2 Versal designs;
  removed the AR000036860 tactical-patch workaround note
* Yocto images: the board-specific kernel arguments (CMA size, and the console on
  Zynq-7000) were set in a variable that the EDF boot flow does not read; they are now
  appended to the EDF `boot.scr` (`BSP_EXTRA_BOOTARGS`). The hostname
  (`<board>-fpgadrv-2025-2`) was overridden by the distribution default `amd-edf` and is
  now applied.
* Yocto images on Zynq UltraScale+ and Versal: the board Ethernet port linked at 1 Gb/s but
  passed no packets, because the generated device tree did not describe the TI DP83867 PHY
  (Linux used the generic PHY driver, without RGMII delays). The PHY is now described, and
  the ZCU104/ZCU106/ZCU111/ZCU208/ZCU216 and VCK190 images use a fixed MAC address.
* Zynq-7000 (PicoZed, ZC706), PetaLinux and Yocto: the board Ethernet port (PS GEM0) is
  enabled with its PHY described in the device tree, instead of being disabled to avoid a
  U-Boot crash; the PicoZed PHY LED configuration is kept.
* ZCU104 Yocto image: added the FSBL patch (already in the PetaLinux BSP) that sets VADJ
  from the FMC card's EEPROM; without it the FMC is unpowered and the SSD is not found.
* Versal Yocto images boot hands-free from a flashed card: `BOOT.BIN` and a design
  `boot.scr` are placed on the FAT partition, and the `boot.scr` enables VADJ at 1.5 V on
  the VCK190/VMK180/VPK120/VPK180 before Linux starts.
* `nvme-cli` added to all Yocto images; the SSD speed-test scripts (already in the Versal
  PetaLinux images) added to the Versal Yocto images.
* Yocto build: works around hosts whose `tar` cannot be used under BitBake's fakeroot
  (`Yocto/scripts/hostfix.sh`).
* Build runner: `package` now rewrites a boot-image zip when its artifacts were rebuilt
  (it used to keep shipping the old zip); the Yocto zip always contains `BOOT.BIN`;
  `clean --keep-boot` removes the rebuildable intermediates but keeps the boot files.
* Fixed the PicoZed 7030 design building its PCIe link at Gen1: since the 2022.1 target
  rename the block-design script compared the board name against the old name, so the
  Gen2 branch never applied. The `pz_7030` design now runs at Gen2 (5 GT/s) as intended
  (not yet verified on hardware)
* Documentation: new [hardware design](design) page with generated block diagrams for each
  device family, the PCIe link of every target and the address map; new
  [Test the SSDs in Linux](linux_test) page with expected `lspci`, `nvme list` and
  throughput results; rewritten Yocto and standalone instructions (the MicroBlaze UART runs
  at 115200 baud); corrected the PCIe IP of the VCU118 design (`xdma`).
* Added per-BSP U-Boot device-tree overlay
  (`meta-xilinx-tools/recipes-bsp/uboot-device-tree/`) for every
  target so U-Boot sees the FMC-side PCIe bridge
* Versal (VCK190/VMK180/VEK280): PCIe PIPE pipeline 2 stages for timing closure. The
  Gen4 root ports now use 2 PIPE pipeline stages between the PCIe block and the GTY quad
  (`pipe_line_stage` / `pipeline_stages`, previously 1), which closes timing on the
  VCK190 FMCP1 design.
* Zynq UltraScale+ (`uzev`, `zcu104`, `zcu106_hpc0`, `zcu106_hpc1`, `zcu111`, `zcu208`,
  `zcu216`): HP-port clock fix. The XDMA Root Ports reached the PS DDR through
  `S_AXI_HP0_FPD` and `S_AXI_HP1_FPD`, which, with the HP-port side of their interconnects,
  were clocked from `pl_clk0` at 99.99 MHz. A 128-bit port at that clock carries at most
  1.60 GB/s, so each SSD slot was capped at 1.60 GB/s, writing and reading, whatever the
  drive. `pl_clk1` is now enabled at 250 MHz, and HP0/HP1 and the HP-port side of their
  interconnects run on it, which gives 4.0 GB/s per port, above the payload rate of a Gen3 x4
  link; the register paths from the PS (`M_AXI_HPM0_FPD`, `M_AXI_HPM1_FPD`) stay on
  `pl_clk0`. The one-lane designs (`zcu104`, `zcu106_hpc1`) get the same clocking but no
  higher rate: their Root Port runs at 125 MHz and 64 bits (~1.0 GB/s), and a Gen3 x1 link
  carries ~985 MB/s anyway. Timing is met on all seven targets with no critical warnings
  (WNS +0.306 ns `uzev`, +1.122 ns `zcu104`, +0.170 ns `zcu106_hpc0`, +1.123 ns
  `zcu106_hpc1`, +0.209 ns `zcu111`, +0.382 ns `zcu208`, +0.236 ns `zcu216`), at a cost of
  ~33 LUTs and 55 registers on `zcu106_hpc0` (not yet verified on hardware). The
  [FPGA Drive Recorder](https://recorder.fpgadrive.com), which is based on this design,
  received the same fix.

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
