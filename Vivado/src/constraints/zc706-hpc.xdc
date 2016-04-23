#GPIO LEDs
set_property PACKAGE_PIN A17 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]

# PCI Express reset (perst)
set_property PACKAGE_PIN AF20 [get_ports perst_n]
set_property IOSTANDARD LVCMOS18 [get_ports perst_n]

# PCI Express reference clock 100MHz
set_property PACKAGE_PIN AD10 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN AD9 [get_ports {ref_clk_clk_n[0]}]

# MGT locations
set_property PACKAGE_PIN AH9 [get_ports {pcie_7x_mgt_rxn[0]}]
set_property PACKAGE_PIN AH10 [get_ports {pcie_7x_mgt_rxp[0]}]
set_property PACKAGE_PIN AK9 [get_ports {pcie_7x_mgt_txn[0]}]
set_property PACKAGE_PIN AK10 [get_ports {pcie_7x_mgt_txp[0]}]

set_property PACKAGE_PIN AJ7 [get_ports {pcie_7x_mgt_rxn[1]}]
set_property PACKAGE_PIN AJ8 [get_ports {pcie_7x_mgt_rxp[1]}]
set_property PACKAGE_PIN AK5 [get_ports {pcie_7x_mgt_txn[1]}]
set_property PACKAGE_PIN AK6 [get_ports {pcie_7x_mgt_txp[1]}]

set_property PACKAGE_PIN AG7 [get_ports {pcie_7x_mgt_rxn[2]}]
set_property PACKAGE_PIN AG8 [get_ports {pcie_7x_mgt_rxp[2]}]
set_property PACKAGE_PIN AJ3 [get_ports {pcie_7x_mgt_txn[2]}]
set_property PACKAGE_PIN AJ4 [get_ports {pcie_7x_mgt_txp[2]}]

set_property PACKAGE_PIN AE7 [get_ports {pcie_7x_mgt_rxn[3]}]
set_property PACKAGE_PIN AE8 [get_ports {pcie_7x_mgt_rxp[3]}]
set_property PACKAGE_PIN AK1 [get_ports {pcie_7x_mgt_txn[3]}]
set_property PACKAGE_PIN AK2 [get_ports {pcie_7x_mgt_txp[3]}]

