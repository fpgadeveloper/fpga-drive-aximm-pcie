#GPIO LEDs
set_property PACKAGE_PIN H23 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS18 [get_ports init_calib_complete]

# PCI Express reset (perst) - IOSTANDARD determined by VADJ which is fixed to 1.8V on KCU105
set_property PACKAGE_PIN W23 [get_ports perst[0]]
set_property IOSTANDARD LVCMOS18 [get_ports perst[0]]

# PEDET - W24 - IOSTANDARD determined by VADJ which is fixed to 1.8V on KCU105

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
set_property PACKAGE_PIN T6 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN T5 [get_ports {ref_clk_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_clk_p -waveform {0.000 5.000} [get_ports ref_clk_clk_p]

# MGT locations - BANK 226
set_property LOC GTHE3_CHANNEL_X0Y8 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/kcu105_lpc_axi_pcie_1_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.kcu105_lpc_axi_pcie_1_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[3].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]
#set_property PACKAGE_PIN Y1 [get_ports {pci_exp_rxn[0]}]
#set_property PACKAGE_PIN Y2 [get_ports {pci_exp_rxp[0]}]
#set_property PACKAGE_PIN AA3 [get_ports {pci_exp_txn[0]}]
#set_property PACKAGE_PIN AA4 [get_ports {pci_exp_txp[0]}]

# KCU105 LPC transceiver is best aligned with PCIE_3_1_X0Y1
set_property LOC PCIE_3_1_X0Y1 [get_cells *_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst]

