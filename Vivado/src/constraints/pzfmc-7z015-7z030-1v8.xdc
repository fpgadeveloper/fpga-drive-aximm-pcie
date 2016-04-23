#GPIO LEDs
set_property PACKAGE_PIN G3 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]

# PCI Express reset (perst)
set_property PACKAGE_PIN V13  [get_ports perst_n]
set_property IOSTANDARD LVCMOS18 [get_ports perst_n]

# PCI Express reference clock 100MHz
set_property PACKAGE_PIN U9   [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN V9   [get_ports {ref_clk_clk_n[0]}]

# MGT locations
set_property PACKAGE_PIN AB7  [get_ports {pcie_7x_mgt_rxn}]
set_property PACKAGE_PIN AA7  [get_ports {pcie_7x_mgt_rxp}]
set_property PACKAGE_PIN AB3  [get_ports {pcie_7x_mgt_txn}]
set_property PACKAGE_PIN AA3  [get_ports {pcie_7x_mgt_txp}]

