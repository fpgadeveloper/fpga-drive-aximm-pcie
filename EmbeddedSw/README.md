Modified BSP files
==================

### axipcie modifications

This project uses a modified version of the axipcie driver.

The `axipcie_v3_3` driver is attached to designs that use the AXI Memory Mapped to PCIe IP (axi_pcie) and 
designs that use the AXI PCIe Gen3 IP (axi_pcie3). However, the driver contains a bug that affects designs
that use the AXI PCIe Gen3 IP.

The script `axipcie_v3_3/data/acipcie.tcl` generates the `xparameters.h` and `xaxipcie_g.c` BSP sources that
both contain a define called `INCLUDE_RC`. To determine the value of this define, the script reads a parameter of 
the PCIe IP called `CONFIG.INCLUDE_RC`, however this parameter only exists in the AXI Memory Mapped to PCIe IP.
Our modified version of the script uses the correct parameter to determine the value of `INCLUDE_RC`.
Specifically, it reads the `CONFIG.device_port_type` parameter and compares it to the value that is expected
for root complex designs: `Root_Port_of_PCI_Express_Root_Complex`.
