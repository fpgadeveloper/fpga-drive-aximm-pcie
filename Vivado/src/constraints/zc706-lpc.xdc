#GPIO LEDs
set_property PACKAGE_PIN A17 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]

# PCI Express reset (perst)
set_property PACKAGE_PIN AE13 [get_ports perst[0]]
set_property IOSTANDARD LVCMOS18 [get_ports perst[0]]

# PCI Express reference clock 100MHz
set_property PACKAGE_PIN U8 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN U7 [get_ports {ref_clk_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_clk_p -waveform {0.000 5.000} [get_ports ref_clk_clk_p]

# MGT locations
set_property PACKAGE_PIN AC3 [get_ports {pcie_7x_mgt_rxn}]
set_property PACKAGE_PIN AC4 [get_ports {pcie_7x_mgt_rxp}]
set_property PACKAGE_PIN AB1 [get_ports {pcie_7x_mgt_txn}]
set_property PACKAGE_PIN AB2 [get_ports {pcie_7x_mgt_txp}]

