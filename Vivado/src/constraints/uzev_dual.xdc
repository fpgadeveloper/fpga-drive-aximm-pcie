# These constraints apply to the UltraZed-EV Carrier with FPGA Drive FMC using 2x SSDs
# ------------------------------------------------------------------------------------

# SSD1 PCI Express reset LA00_P_CC (perst_0) (HP_DP_12_GC_P) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN AF16 [get_ports {perst_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# SSD2 PCI Express reset LA04_P (perst_1) (HP_DP_02_P) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN AH17 [get_ports {perst_1[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst_1[0]}]

# PEDET_0 - LA00_N_CC - F16 - IOSTANDARD determined by VADJ
# PEDET_1 - LA04_N - L16 - IOSTANDARD determined by VADJ

# Disable signal for 3.3V power supply for SSD2 - LA07_P (disable_ssd2_pwr) (HP_DP_05_P)
set_property PACKAGE_PIN AA16 [get_ports disable_ssd2_pwr]
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
# SSD1 ref clock connects to MGT bank 225, CLK0 input
set_property PACKAGE_PIN L8 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN L7 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]
# SSD2 ref clock connects to MGT bank 224, CLK0 input
set_property PACKAGE_PIN R8 [get_ports {ref_clk_1_clk_p[0]}]
set_property PACKAGE_PIN R7 [get_ports {ref_clk_1_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_1_clk_p -waveform {0.000 5.000} [get_ports ref_clk_1_clk_p]

# MGT locations
# SSD1 HPC0_DP0-3 (PCIe lanes 0-3) are connected to MGT bank 225 (X0Y8-X0Y11) in this order: 0->0, 1->1, 2->2, 3->3
set_property LOC GTHE4_CHANNEL_X0Y8  [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[2].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y9  [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[2].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y10 [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[2].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[2].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y11 [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[2].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[3].GTHE4_CHANNEL_PRIM_INST}]

# SSD2 HPC0_DP4-7 (PCIe lanes 0-3) are connected to MGT bank 224 (X0Y4-X0Y7) in this order: 0->0, 1->1, 2->2, 3->3
set_property LOC GTHE4_CHANNEL_X0Y4 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y5 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y6 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[2].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y7 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[3].GTHE4_CHANNEL_PRIM_INST}]

# UltraZed-EV FMC transceivers for SSD1 are best aligned with PCIE_X0Y1
set_property LOC PCIE40E4_X0Y1 [get_cells *_i/xdma_0/inst/pcie4_ip_i/inst/*_pcie_4_0_pipe_inst/pcie_4_0_e4_inst]

# UltraZed-EV FMC transceivers for SSD2 are best aligned with PCIE_X0Y0
set_property LOC PCIE40E4_X0Y0 [get_cells *_i/xdma_1/inst/pcie4_ip_i/inst/*_pcie_4_0_pipe_inst/pcie_4_0_e4_inst]

