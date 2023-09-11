# These constraints apply to the ZCU208 FMC+ with FPGA Drive FMC using SSD1 only
# ------------------------------------------------------------------------------

# SSD1 PCI Express reset LA00_P_CC (perst_0) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN F21 [get_ports {perst_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# PEDET_0 - LA00_N_CC - F22 - IOSTANDARD determined by VADJ

# Disable signal for 3.3V power supply for SSD2 - LA07_P (disable_ssd2_pwr)
set_property PACKAGE_PIN C23 [get_ports disable_ssd2_pwr]
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
# SSD1 ref clock connects to MGT bank 130, CLK0 input
set_property PACKAGE_PIN U33 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN U34 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

# MGT locations
# SSD1 FMCP_DP0-3 (PCIe lanes 0-3) are connected to MGT bank 130 (X0Y12-X0Y15) in this order: 0->0, 1->1, 2->2, 3->3
set_property LOC GTYE4_CHANNEL_X0Y12 [get_cells {*_i/xdma_0/inst/pcie4c_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.*_xdma_0_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[*].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y13 [get_cells {*_i/xdma_0/inst/pcie4c_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.*_xdma_0_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[*].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[1].GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y14 [get_cells {*_i/xdma_0/inst/pcie4c_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.*_xdma_0_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[*].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[2].GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y15 [get_cells {*_i/xdma_0/inst/pcie4c_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.*_xdma_0_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[*].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[3].GTYE4_CHANNEL_PRIM_INST}]

# ZCU208 FMC+ transceivers for SSD1 are best aligned with PCIE_X0Y1
set_property LOC PCIE4CE4_X0Y1 [get_cells *_i/xdma_0/inst/pcie4c_ip_i/inst/*_pcie_4_0_pipe_inst/pcie_4_c_e4_inst]

