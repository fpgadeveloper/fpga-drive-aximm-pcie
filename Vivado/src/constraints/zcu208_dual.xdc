# These constraints apply to the ZCU208 FMC+ with FPGA Drive FMC using 2x SSDs
# ----------------------------------------------------------------------------

# SSD1 PCI Express reset LA00_P_CC (perst_0) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN F21 [get_ports {perst_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# SSD2 PCI Express reset LA04_P (perst_1) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN C20 [get_ports {perst_1[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst_1[0]}]

# PEDET_0 - LA00_N_CC - F22 - IOSTANDARD determined by VADJ
# PEDET_1 - LA04_N - B20 - IOSTANDARD determined by VADJ

# Disable signal for 3.3V power supply for SSD2 - LA07_P (disable_ssd2_pwr)
set_property PACKAGE_PIN C23 [get_ports disable_ssd2_pwr]
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
# SSD1 ref clock connects to MGT bank 130, CLK0 input
set_property PACKAGE_PIN U33 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN U34 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]
# SSD2 ref clock connects to MGT bank 131, CLK0 input
set_property PACKAGE_PIN P31 [get_ports {ref_clk_1_clk_p[0]}]
set_property PACKAGE_PIN P32 [get_ports {ref_clk_1_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_1_clk_p -waveform {0.000 5.000} [get_ports ref_clk_1_clk_p]

# MGT locations
# SSD1 FMCP_DP0-3 (PCIe lanes 0-3) are connected to MGT bank 130 (X0Y12-X0Y15) in this order: 0->0, 1->1, 2->2, 3->3
set_property LOC GTYE4_CHANNEL_X0Y12 [get_cells {*_i/xdma_0/inst/pcie4c_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.*_xdma_0_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[*].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y13 [get_cells {*_i/xdma_0/inst/pcie4c_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.*_xdma_0_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[*].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[1].GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y14 [get_cells {*_i/xdma_0/inst/pcie4c_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.*_xdma_0_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[*].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[2].GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y15 [get_cells {*_i/xdma_0/inst/pcie4c_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.*_xdma_0_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[*].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[3].GTYE4_CHANNEL_PRIM_INST}]

# SSD2 FMCP_DP4-7 (PCIe lanes 0-3) are connected to MGT bank 131 (X0Y16-X0Y19) in this order: 0->0, 1->1, 2->2, 3->3
set_property LOC GTYE4_CHANNEL_X0Y16 [get_cells {*_i/xdma_1/inst/pcie4c_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.*_xdma_1_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[*].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y17 [get_cells {*_i/xdma_1/inst/pcie4c_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.*_xdma_1_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[*].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[1].GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y18 [get_cells {*_i/xdma_1/inst/pcie4c_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.*_xdma_1_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[*].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[2].GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y19 [get_cells {*_i/xdma_1/inst/pcie4c_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.*_xdma_1_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[*].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[3].GTYE4_CHANNEL_PRIM_INST}]

# ZCU208 FMC+ transceivers for SSD1 are best aligned with PCIE_X0Y1
set_property LOC PCIE4CE4_X0Y0 [get_cells *_i/xdma_0/inst/pcie4c_ip_i/inst/*_pcie_4_0_pipe_inst/pcie_4_c_e4_inst]

# ZCU208 FMC+ transceivers for SSD2 are best aligned with PCIE_X0Y0
set_property LOC PCIE4CE4_X0Y1 [get_cells *_i/xdma_1/inst/pcie4c_ip_i/inst/*_pcie_4_0_pipe_inst/pcie_4_c_e4_inst]

# The following LOC and USER_CLOCK_ROOT constraints correct a timing issue that 
# started happening in the ZCU208 dual design with the 2022.1 version of Vivado.
# This forum post led to the solution:
# https://support.xilinx.com/s/question/0D52E00006nAusUSAS/what-can-i-do-to-fix-a-max-skew-violation-on-the-pcie-pipeclk-port-i-consistently-have-pulse-width-violations-that-are-related-to-this-clock-the-rest-of-the-design-meets-timing?language=en_US
# We simply copied the positions of these two BUFG_GTs from the same design in version 2020.2
# and used the USER_CLOCK_ROOT property to assign the output nets to the same CLOCK_ROOT.
set_property LOC BUFG_GT_X0Y161 [get_cells *_i/xdma_0/inst/pcie4c_ip_i/inst/fpgadrv_xdma_0_0_pcie4c_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_coreclk]
set_property LOC BUFG_GT_X0Y164 [get_cells *_i/xdma_0/inst/pcie4c_ip_i/inst/fpgadrv_xdma_0_0_pcie4c_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_pclk]
set_property USER_CLOCK_ROOT X0Y5 [get_nets *_i/xdma_0/inst/pcie4c_ip_i/inst/fpgadrv_xdma_0_0_pcie4c_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/CLK_CORECLK]
set_property USER_CLOCK_ROOT X0Y5 [get_nets *_i/xdma_0/inst/pcie4c_ip_i/inst/fpgadrv_xdma_0_0_pcie4c_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/CLK_PCLK2_GT]

