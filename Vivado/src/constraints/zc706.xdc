#GPIO LEDs
set_property PACKAGE_PIN A17 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]

# PCI Express reset (perst)
set_property PACKAGE_PIN AK23 [get_ports perst_n]
set_property IOSTANDARD LVCMOS18 [get_ports perst_n]

# PCI Express reference clock 100MHz
set_property PACKAGE_PIN N8 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN N7 [get_ports {ref_clk_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_clk_p -waveform {0.000 5.000} [get_ports ref_clk_clk_p]

# MGT locations
set_property PACKAGE_PIN P5 [get_ports {pcie_7x_mgt_rxn[0]}]
set_property PACKAGE_PIN P6 [get_ports {pcie_7x_mgt_rxp[0]}]
set_property PACKAGE_PIN N3 [get_ports {pcie_7x_mgt_txn[0]}]
set_property PACKAGE_PIN N4 [get_ports {pcie_7x_mgt_txp[0]}]

set_property PACKAGE_PIN T5 [get_ports {pcie_7x_mgt_rxn[1]}]
set_property PACKAGE_PIN T6 [get_ports {pcie_7x_mgt_rxp[1]}]
set_property PACKAGE_PIN P1 [get_ports {pcie_7x_mgt_txn[1]}]
set_property PACKAGE_PIN P2 [get_ports {pcie_7x_mgt_txp[1]}]

set_property PACKAGE_PIN U3 [get_ports {pcie_7x_mgt_rxn[2]}]
set_property PACKAGE_PIN U4 [get_ports {pcie_7x_mgt_rxp[2]}]
set_property PACKAGE_PIN R3 [get_ports {pcie_7x_mgt_txn[2]}]
set_property PACKAGE_PIN R4 [get_ports {pcie_7x_mgt_txp[2]}]

set_property PACKAGE_PIN V5 [get_ports {pcie_7x_mgt_rxn[3]}]
set_property PACKAGE_PIN V6 [get_ports {pcie_7x_mgt_rxp[3]}]
set_property PACKAGE_PIN T1 [get_ports {pcie_7x_mgt_txn[3]}]
set_property PACKAGE_PIN T2 [get_ports {pcie_7x_mgt_txp[3]}]

