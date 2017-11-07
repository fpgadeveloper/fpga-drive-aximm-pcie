#GPIO LEDs
set_property PACKAGE_PIN AP8 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS18 [get_ports init_calib_complete]

# PCI Express reset (perst) - IOSTANDARD determined by VADJ which is fixed to 1.8V on KCU105
set_property PACKAGE_PIN H11 [get_ports {perst[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst[0]}]

# PEDET - G11 - IOSTANDARD determined by VADJ which is fixed to 1.8V on KCU105

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
set_property PACKAGE_PIN K6 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN K5 [get_ports {ref_clk_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_clk_p -waveform {0.000 5.000} [get_ports ref_clk_clk_p]

# MGT locations
set_property LOC GTHE3_CHANNEL_X0Y16 [get_cells {*_i/axi_pcie3_0/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_0_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_0_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[4].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]
#set_property PACKAGE_PIN E3 [get_ports {pci_exp_rxn[0]}]
#set_property PACKAGE_PIN E4 [get_ports {pci_exp_rxp[0]}]
#set_property PACKAGE_PIN F5 [get_ports {pci_exp_txn[0]}]
#set_property PACKAGE_PIN F6 [get_ports {pci_exp_txp[0]}]
set_property LOC GTHE3_CHANNEL_X0Y17 [get_cells {*_i/axi_pcie3_0/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_0_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_0_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[4].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[1].GTHE3_CHANNEL_PRIM_INST}]
#set_property PACKAGE_PIN D1 [get_ports {pci_exp_rxn[1]}]
#set_property PACKAGE_PIN D2 [get_ports {pci_exp_rxp[1]}]
#set_property PACKAGE_PIN D5 [get_ports {pci_exp_txn[1]}]
#set_property PACKAGE_PIN D6 [get_ports {pci_exp_txp[1]}]
set_property LOC GTHE3_CHANNEL_X0Y18 [get_cells {*_i/axi_pcie3_0/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_0_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_0_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[4].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[2].GTHE3_CHANNEL_PRIM_INST}]
#set_property PACKAGE_PIN B1 [get_ports {pci_exp_rxn[2]}]
#set_property PACKAGE_PIN B2 [get_ports {pci_exp_rxp[2]}]
#set_property PACKAGE_PIN C3 [get_ports {pci_exp_txn[2]}]
#set_property PACKAGE_PIN C4 [get_ports {pci_exp_txp[2]}]
set_property LOC GTHE3_CHANNEL_X0Y19 [get_cells {*_i/axi_pcie3_0/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_0_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_0_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[4].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[3].GTHE3_CHANNEL_PRIM_INST}]
#set_property PACKAGE_PIN A3 [get_ports {pci_exp_rxn[3]}]
#set_property PACKAGE_PIN A4 [get_ports {pci_exp_rxp[3]}]
#set_property PACKAGE_PIN B5 [get_ports {pci_exp_txn[3]}]
#set_property PACKAGE_PIN B6 [get_ports {pci_exp_txp[3]}]

# KCU105 HPC transceivers are best aligned with PCIE_X0Y2
set_property LOC PCIE_3_1_X0Y2 [get_cells *_i/axi_pcie3_0/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst]

#QSPI
set_property PACKAGE_PIN M20 [ get_ports spi_rtl_io0_io]
set_property IOSTANDARD LVCMOS18 [ get_ports spi_rtl_io0_io]

set_property PACKAGE_PIN L20 [ get_ports spi_rtl_io1_io]
set_property IOSTANDARD LVCMOS18 [ get_ports spi_rtl_io1_io]

set_property PACKAGE_PIN R22 [ get_ports spi_rtl_io2_io]
set_property IOSTANDARD LVCMOS18 [ get_ports spi_rtl_io2_io]

set_property PACKAGE_PIN R21 [ get_ports spi_rtl_io3_io]
set_property IOSTANDARD LVCMOS18 [ get_ports spi_rtl_io3_io]

set_property PACKAGE_PIN G26 [ get_ports spi_rtl_ss_io]
set_property IOSTANDARD LVCMOS18 [ get_ports spi_rtl_ss_io]

# SCK not used - loc it to unused pin: GPIO_LED_1_LS
set_property PACKAGE_PIN H23 [ get_ports spi_rtl_sck_io]
set_property IOSTANDARD LVCMOS18 [ get_ports spi_rtl_sck_io]
