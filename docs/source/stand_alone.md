# Stand-alone Application

A stand-alone software application can be built for this project using the build script contained in the 
Vitis subdirectory of this repo. The build script creates a Vitis workspace containing the hardware platform 
(exported from Vivado) and a stand-alone application. The application originates from an example provided by 
Xilinx which is located in the Vitis installation files.
The program demonstrates basic usage of the stand-alone driver including how to check link-up, link speed, 
the number of lanes used, as well as how to perform PCIe enumeration. The original example applications can 
be viewed on the [embeddedsw Github repo](https://github.com/Xilinx/embeddedsw/tree/xlnx_rel_v2025.2):

* For the AXI PCIe designs:
  [xaxipcie_rc_enumerate_example.c](https://github.com/Xilinx/embeddedsw/blob/xlnx_rel_v2025.2/XilinxProcessorIPLib/drivers/axipcie/examples/xaxipcie_rc_enumerate_example.c)
* For the XDMA and QDMA designs:
  [xdmapcie_rc_enumerate_example.c](https://github.com/Xilinx/embeddedsw/blob/xlnx_rel_v2025.2/XilinxProcessorIPLib/drivers/xdmapcie/examples/xdmapcie_rc_enumerate_example.c)

Note that the repo carries lightly modified copies of these examples in
`Vitis/common/src/` (see [advanced](advanced) for the modifications).

## Prerequisites

* Vivado and Vitis 2025.2 (Windows or Linux — see [requirements](requirements)).
* The target board with its USB-UART and USB-JTAG cables.
* For the Zynq-7000, Zynq UltraScale+ and Versal boards: a micro-SD card, if you want to
  boot the application from SD rather than over JTAG.
* The [FPGA Drive FMC Gen4] or M.2 M-key Stack FMC with one or two M.2 NVMe SSDs.

## Build the application

Run the following from the root of the repository (`build.bat` instead of `./build.sh` in a
plain Windows command prompt):

```
./build.sh standalone --target <target>
```

The runner builds the Vivado project and XSA first if needed, then creates the Vitis
workspace (platform + `ssd_test` application) and packages the boot file. See the
[build instructions](build_instructions.md#build-vitis-workspace) for the list of valid
targets. The outputs are:

| Output | Location |
|--------|----------|
| Vitis workspace | `Vitis/<target>_workspace/` |
| Boot file, Zynq-7000 / Zynq UltraScale+ / Versal | `Vitis/boot/<target>/BOOT.BIN` (FSBL or PLM + bitstream/PDI + `ssd_test`) |
| Boot file, MicroBlaze | `Vitis/boot/<target>/fpgadrv_boot.bit` (bitstream with `ssd_test` in MicroBlaze local memory) |
| Zip of the boot files | `bootimages/fpga-drive-aximm-pcie_<target>_standalone-2025-2.zip` (after `./build.sh package` or `all`) |

## Hardware setup

1. Connect one or more SSDs to the mezzanine card and then plug it into the FMC connector of
   your target design. Designs with only one active slot use the slot labelled "SSD1" /
   "SLOT 1". Instructions for doing this can be found in the
   [Getting started](https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/getting-started/) guide.
2. Connect the USB-UART of the development board to your PC and open a terminal program
   such as [Putty] at **115200 baud** (8N1). This applies to all designs, including the
   MicroBlaze designs (AXI UART Lite at 115200 baud).
3. Connect the USB-JTAG if you are going to load the application over JTAG.

## Run the application

### From the SD card (Zynq-7000, Zynq UltraScale+, Versal)

1. Copy `Vitis/boot/<target>/BOOT.BIN` to the first (FAT32) partition of a micro-SD card.
2. Set the board to boot from the SD card (the switch settings are listed under
   [Boot PetaLinux](petalinux.md#boot-petalinux); for the Versal boards, see the board's
   user guide) and insert the card.
3. Power up the board. The application runs immediately and prints its output to the UART.

### Over JTAG — MicroBlaze designs

1. Power up the board and open the Vivado Hardware Manager (**Open Hardware Manager →
   Open Target → Auto Connect**).
2. **Program Device** with `Vitis/boot/<target>/fpgadrv_boot.bit`. The application is part
   of the bitstream, so it starts as soon as the FPGA is configured.

### Over JTAG — from the Vitis IDE

1. Set the board to JTAG boot mode (the switch settings are listed under
   [Boot via JTAG](petalinux.md#setup-hardware)) and power it up.
2. Launch Vitis 2025.2 and open the workspace `Vitis/<target>_workspace`.
3. Select the `ssd_test` application component and click **Run** (or **Debug**) in the
   flow navigator. Vitis programs the device and loads and starts the application.

## Expected output

The application initializes the Root Port, waits for the link, prints the state of the
link and then enumerates the PCIe tree: the Root Port (a Xilinx bridge, vendor ID `10EE`)
on bus 00 and the SSD (an end point) on bus 01. With a Samsung SSD, for example, the
end point has vendor ID `144D`. The output differs slightly with the PCIe IP used by the
design:

### Output of XDMA designs

```none
Zynq MP First Stage Boot Loader
Release 2025.2   May 14 2026  -  14:56:34
PMU-FW is not running, certain applications may not be supported.
Interrupts currently enabled are        0
Interrupts currently pending are        0
Interrupts currently enabled are        0
Interrupts currently pending are        0
Link is up
Bus Number is 00
Device Number is 00
Function Number is 00
Port Number is 00
PCIe Local Config Space is   100147 at register CommandStatus
PCIe Local Config Space is    70100 at register Prim Sec. Bus
Root Complex IP Instance has been successfully initialized
xdma_pcie:
PCIeBus is 00
PCIeDev is 00
PCIeFunc is 00
xdma_pcie: Vendor ID is 10EE
Device ID is 9131
xdma_pcie: This is a Bridge
xdma_pcie: bus: 00, device: 00, function: 00: BAR 0 is not implemented
xdma_pcie: bus: 00, device: 00, function: 00: BAR 1 is not implemented
xdma_pcie:
PCIeBus is 01
PCIeDev is 00
PCIeFunc is 00
xdma_pcie: Vendor ID is 144D
Device ID is A80A
xdma_pcie: This is an End Point
xdma_pcie: bus: 01, device: 00, function: 00: BAR 0, ADDR: 0xA1000000 size : 16K
xdma_pcie: bus: 01, device: 00, function: 00: BAR 1required IO space; it is unassigned
xdma_pcie: bus: 01, device: 00, function: 00: BAR 2 is not implemented
xdma_pcie: bus: 01, device: 00, function: 00: BAR 3 is not implemented
xdma_pcie: bus: 01, device: 00, function: 00: BAR 4 is not implemented
xdma_pcie: bus: 01, device: 00, function: 00: BAR 5 is not implemented
xdma_pcie: End Point has been enabled
Successfully ran XdmaPcie rc enumerate Example
```

### Output of AXI PCIe designs

```none
Interrupts currently enabled are        0
Interrupts currently pending are        0
Interrupts currently enabled are        0
Interrupts currently pending are        0
Link is up
Bus Number is 00
Device Number is 00
Function Number is 00
Port Number is 00
PCIe Local Config Space is   100147 at register CommandStatus
PCIe Local Config Space is    70100 at register Prim Sec. Bus
Root Complex IP Instance has been successfully initialized
Start Enumeration of PCIe Fabric on This System
PCIeBus is 00
PCIeDev is 00
PCIeFunc is 00
Vendor ID is 10EE
This is a Bridge
PCIeBus is 01
PCIeDev is 00
PCIeFunc is 00
Vendor ID is 144D
This is an End Point
End Point has been enabled
End of Enumeration of PCIe Fabric on This system
Successfully ran Axipcie rc enumerate Example
```

### Output of the QDMA designs

```none
VADJ: 1.5V enabled successfully
Interrupts currently enabled are        0
Interrupts currently pending are        0
Interrupts currently enabled are        0
Interrupts currently pending are        0
Link is up
Bus Number is 00
Device Number is 00
Function Number is 00
Port Number is 00
PCIe Local Config Space is        0 at register CommandStatus
PCIe Local Config Space is        0 at register Prim Sec. Bus
Root Complex IP Instance has been successfully initialized
xdma_pcie:
PCIeBus is 00
PCIeDev is 00
PCIeFunc is 00
xdma_pcie: Vendor ID is 10EE
Device ID is B048
xdma_pcie: This is a Bridge
xdma_pcie: Requested BAR size of 4292870144K for bus: 00, dev: 00, function: 00 is out of range 
                xdma_pcie:
PCIeBus is 01
PCIeDev is 00
PCIeFunc is 00
xdma_pcie: Vendor ID is 144D
Device ID is A80A
xdma_pcie: This is an End Point
xdma_pcie: bus: 01, device: 00, function: 00: BAR 0, ADDR: 0xA8000000 size : 16K
xdma_pcie: bus: 01, device: 00, function: 00: BAR 1required IO space; it is unassigned
xdma_pcie: bus: 01, device: 00, function: 00: BAR 2 is not implemented
xdma_pcie: bus: 01, device: 00, function: 00: BAR 3 is not implemented
xdma_pcie: bus: 01, device: 00, function: 00: BAR 4 is not implemented
xdma_pcie: bus: 01, device: 00, function: 00: BAR 5 is not implemented
xdma_pcie: End Point has been enabled
Successfully ran XdmaPcie rc enumerate Example
```

If you see `Link is not up` instead, see [troubleshooting](troubleshooting).

## Changing Target Slot

The application tests one M.2 slot: SSD1 by default. In designs that support two M.2 slots,
you can change the target slot by modifying a define value in the
example application (in `Vitis/common/src/`), then rebuild with
`./build.sh standalone --target <target>`. The table below shows the lines to modify and
their potential values.

|  | AXI PCIe designs | XDMA and QDMA designs |
|--|------------------|-----------------------|
| **File to modify** | `xaxipcie_rc_enumerate_example.c` | `xdmapcie_rc_enumerate_example.c` |
| **Define** | XPAR_XAXIPCIE_0_BASEADDR | XPAR_XXDMAPCIE_0_BASEADDR |
| **M.2 Slot 1** | XPAR_XAXIPCIE_0_BASEADDR | XPAR_XXDMAPCIE_0_BASEADDR |
| **M.2 Slot 2** | XPAR_XAXIPCIE_1_BASEADDR | XPAR_XXDMAPCIE_1_BASEADDR |

## Advanced Design Details

### Linker script modifications for MicroBlaze designs

For the MicroBlaze designs, the Vitis linker script generator may assign sections across
multiple memory regions. To ensure the application runs correctly, the Vitis build script
modifies the generated linker script and reassigns all sections to local memory.

If you want to manually create an application in the Vitis for one of the MicroBlaze designs,
you will have to manually modify the automatically generated linker script, and set all sections
to local memory.

### axipcie driver

This project uses a modified version of the axipcie driver.

The `axipcie_v3_4` driver is used by designs that use the AXI Memory Mapped to PCIe IP (axi_pcie) and
designs that use the AXI PCIe Gen3 IP (axi_pcie3). However, the driver's SDT device tree binding file
`axipcie_v3_4/data/axipcie.yaml` only declares the compatible string `xlnx,axi-pcie-host-1.00.a`, which
matches the older AXI Memory Mapped to PCIe IP. It does not include `xlnx,axi-pcie3-3.0`, which is the
compatible string used by the AXI PCIe Gen3 IP in the device tree. As a result, the SDT driver mapping
fails to associate the IP with the axipcie driver, and the BSP is built without the driver.

Our modified version of `axipcie.yaml` adds `xlnx,axi-pcie3-3.0` as a compatible string so that the
driver is correctly included in the BSP for designs that use the AXI PCIe Gen3 IP.

Additionally, the YAML's `required` list names the device tree property that populates the config table's
`IncludeRootComplex` field — the flag the example application checks to confirm the IP is a root port. The
two IPs publish that flag under *different* property names, and the YAML can only name one of them:

| PCIe IP | designs | device tree property | value for a root port |
|---------|---------|----------------------|-----------------------|
| `axi_pcie` (Gen2) | kc705, vc707, zc706, PicoZed | `xlnx,port-type` | `1` |
| `axi_pcie3` (Gen3) | kcu105, vc709 | `xlnx,dev-port-type` | `2` |

Whichever property the YAML names, the other IP's node does not have it, the BSP generator writes `0` into
`IncludeRootComplex`, and the application aborts with *"Failed to initialize...AXI PCIE is configured as
endpoint"* even though the IP really is a root port. The Vitis build script (`Vitis/py/build-vitis.py`)
therefore inspects the XSA and sets the YAML's `required` entry to the property that this design's PCIe IP
actually publishes, before the platform is built.

Note that for the Gen3 IP the value is `2` (PCI Express Root Port), while the driver expects `1`
(`XAXIPCIE_IS_RC`). The example application normalizes any non-zero value to `1` after initialization to
satisfy the driver's internal assertions.

### xdmapcie driver

This project uses a modified version of the xdmapcie driver.

The `xdmapcie_v3_1` driver is used by designs that use the QDMA IP. The driver's `CfgInitialize` function
contains hardcoded address values for swapping the ECAM (PCIe config space) and CSR (control/status register)
base addresses. These hardcoded values do not match the address map of this project's designs, causing the
driver to access the wrong address regions. Specifically, local config space reads/writes and PCIe fabric
enumeration fail because the driver's `BaseAddress` and `Ecam` fields point to incorrect locations.

Our modified version of `xdmapcie.c` replaces the hardcoded address swap with a generic swap that uses the
actual values from the configuration table. This ensures the driver works correctly regardless of the
design's address map.

Additionally, the SDT config generator populates the `NpMemBaseAddr` and `PMemBaseAddr` fields with
PCIe-side offsets (zero-based) from the device tree `ranges` property, instead of the CPU-side absolute
addresses needed for BAR assignment. The example application (`xdmapcie_rc_enumerate_example.c`) corrects
these values after driver initialization using the actual addresses from `xparameters.h`.

### Modifications to the AXI PCIe example application

The AXI PCIe example application (`xaxipcie_rc_enumerate_example.c`) is based on the AMD driver example
with the following modification:

* **IncludeRootComplex normalization** — The SDT device tree property `xlnx,dev-port-type` provides the
  PCI Express port type value (e.g. `2` for Root Port), but the driver's internal assertions expect
  `IncludeRootComplex` to be exactly `1`. The application normalizes any non-zero value to
  `XAXIPCIE_IS_RC` (`1`) after driver initialization to prevent assertion failures.

### Modifications to the QDMA example application

The QDMA example application (`xdmapcie_rc_enumerate_example.c`) is based on the AMD driver example with
the following modifications:

* **VADJ enable** — On most Versal boards (vck190, vmk180, vpk120, vpk180, vhk158), the VADJ supply that
  powers the FMC+ connector I/Os is not enabled by default. Without VADJ, the PCIe link cannot be
  established because the FMC signals are unpowered. The application calls `vadj_enable(VADJ_1V5)` before
  PCIe initialization to configure the board's power controller via I2C. On the vek280, VADJ is enabled
  by default so this call is a no-op.
* **NpMem/PMem address fix** — After driver initialization, the application corrects the non-prefetchable
  and prefetchable memory base addresses using the actual CPU-side addresses from `xparameters.h`
  (`XPAR_QDMA_0_BASEADDR_2` and `XPAR_QDMA_0_BASEADDR_3`). This is needed because the SDT config
  generator populates these fields with PCIe-side offsets instead of absolute addresses, which would
  otherwise cause BARs to be assigned at address 0x0.

[Putty]: https://www.putty.org/
[FPGA Drive FMC Gen4]: https://docs.opsero.com/op063/datasheet/overview/

