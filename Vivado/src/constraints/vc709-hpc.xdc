#GPIO LEDs
set_property PACKAGE_PIN AM39 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]
set_property PACKAGE_PIN AN39 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS18 [get_ports init_calib_complete]

# PCI Express reset (perst) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN K39 [get_ports perst[0]]
set_property IOSTANDARD LVCMOS18 [get_ports perst[0]]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN G10 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN G9 [get_ports {ref_clk_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_clk_p -waveform {0.000 5.000} [get_ports ref_clk_clk_p]

# MGT locations
set_property LOC GTHE2_CHANNEL_X1Y36 [get_cells {*_i/axi_pcie3_0/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN D7 [get_ports {pci_exp_rxn[0]}]
set_property PACKAGE_PIN D8 [get_ports {pci_exp_rxp[0]}]
set_property PACKAGE_PIN E1 [get_ports {pci_exp_txn[0]}]
set_property PACKAGE_PIN E2 [get_ports {pci_exp_txp[0]}]

set_property LOC GTHE2_CHANNEL_X1Y37 [get_cells {*_i/axi_pcie3_0/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN C5 [get_ports {pci_exp_rxn[1]}]
set_property PACKAGE_PIN C6 [get_ports {pci_exp_rxp[1]}]
set_property PACKAGE_PIN D3 [get_ports {pci_exp_txn[1]}]
set_property PACKAGE_PIN D4 [get_ports {pci_exp_txp[1]}]

set_property LOC GTHE2_CHANNEL_X1Y38 [get_cells {*_i/axi_pcie3_0/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN B7 [get_ports {pci_exp_rxn[2]}]
set_property PACKAGE_PIN B8 [get_ports {pci_exp_rxp[2]}]
set_property PACKAGE_PIN C1 [get_ports {pci_exp_txn[2]}]
set_property PACKAGE_PIN C2 [get_ports {pci_exp_txp[2]}]

set_property LOC GTHE2_CHANNEL_X1Y39 [get_cells {*_i/axi_pcie3_0/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN A5 [get_ports {pci_exp_rxn[3]}]
set_property PACKAGE_PIN A6 [get_ports {pci_exp_rxp[3]}]
set_property PACKAGE_PIN B3 [get_ports {pci_exp_txn[3]}]
set_property PACKAGE_PIN B4 [get_ports {pci_exp_txp[3]}]

# PCIe integrated block
set_property BEL PCIE_3_0 [get_cells *_i/axi_pcie3_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/PCIE_3_0_i]
set_property LOC PCIE3_X0Y2 [get_cells *_i/axi_pcie3_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/PCIE_3_0_i]


