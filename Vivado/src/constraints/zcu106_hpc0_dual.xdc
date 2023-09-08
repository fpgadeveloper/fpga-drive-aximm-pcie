# These constraints apply to the ZCU106 HPC0 with FPGA Drive FMC using 2x SSDs
# ----------------------------------------------------------------------------

# SSD1 PCI Express reset LA00_P_CC (perst_0) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN F17 [get_ports {perst_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# SSD2 PCI Express reset LA04_P (perst_1) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN L17 [get_ports {perst_1[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst_1[0]}]

# PEDET_0 - LA00_N_CC - F16 - IOSTANDARD determined by VADJ
# PEDET_1 - LA04_N - L16 - IOSTANDARD determined by VADJ

# Disable signal for 3.3V power supply for SSD2 - LA07_P (disable_ssd2_pwr)
set_property PACKAGE_PIN J16 [get_ports disable_ssd2_pwr]
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
# SSD1 ref clock connects to MGT bank 226, CLK0 input
set_property PACKAGE_PIN V8 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN V7 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]
# SSD2 ref clock connects to MGT bank 227, CLK0 input
set_property PACKAGE_PIN T8 [get_ports {ref_clk_1_clk_p[0]}]
set_property PACKAGE_PIN T7 [get_ports {ref_clk_1_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_1_clk_p -waveform {0.000 5.000} [get_ports ref_clk_1_clk_p]

# MGT locations
# SSD1 HPC0_DP0-3 (PCIe lanes 0-3) are connected to MGT bank 226 (X0Y12-X0Y15) in this order: 0->2, 1->1, 2->3, 3->0
# To rearrange the preplacement, we do this: 0->X0Y11 (temporary), 3->X0Y12, 2->X0Y15, 0->X0Y14, 1->X0Y13 (already placed)
set_property LOC GTHE4_CHANNEL_X0Y11 [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[3].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y12 [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[3].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[3].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y15 [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[3].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[2].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y14 [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[3].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y13 [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[3].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]

# SSD2 HPC0_DP4-7 (PCIe lanes 0-3) are connected to MGT bank 227 (X0Y16-X0Y19) in this order: 0->3, 1->1, 2->0, 3->2
# To rearrange the preplacement, we do this: 0->X0Y11 (temporary), 2->X0Y16, 3->X0Y18, 0->X0Y19, 1->X0Y17 (already placed)
set_property LOC GTHE4_CHANNEL_X0Y11 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[4].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y16 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[4].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[2].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y18 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[4].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[3].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y19 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[4].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y17 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[4].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]

# ZCU106 HPC0 transceivers for SSD1 are best aligned with PCIE_X0Y1
set_property LOC PCIE40E4_X0Y1 [get_cells *_i/xdma_0/inst/pcie4_ip_i/inst/*_pcie_4_0_pipe_inst/pcie_4_0_e4_inst]

# ZCU106 HPC0 transceivers for SSD2 are best aligned with PCIE_X0Y0
set_property LOC PCIE40E4_X0Y0 [get_cells *_i/xdma_1/inst/pcie4_ip_i/inst/*_pcie_4_0_pipe_inst/pcie_4_0_e4_inst]

