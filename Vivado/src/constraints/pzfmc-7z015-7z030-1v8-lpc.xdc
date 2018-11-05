#GPIO LEDs
set_property PACKAGE_PIN G3 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]

# Disable signal for 3.3V power supply for SSD2 - LA07_P (disable_ssd2_pwr)
set_property PACKAGE_PIN C6 [get_ports disable_ssd2_pwr]
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

# PCI Express reset (perst)
set_property PACKAGE_PIN B4 [get_ports perst[0]]
set_property IOSTANDARD LVCMOS18 [get_ports perst[0]]

# PCI Express reference clock 100MHz
set_property PACKAGE_PIN U5 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN V5 [get_ports {ref_clk_clk_n[0]}]

create_clock -period 10.000 -name ref_clk_clk_p -waveform {0.000 5.000} [get_ports ref_clk_clk_p]

# MGT locations
set_property PACKAGE_PIN Y6 [get_ports {pcie_7x_mgt_rxn}]
set_property PACKAGE_PIN W6 [get_ports {pcie_7x_mgt_rxp}]
set_property PACKAGE_PIN Y2 [get_ports {pcie_7x_mgt_txn}]
set_property PACKAGE_PIN W2 [get_ports {pcie_7x_mgt_txp}]

