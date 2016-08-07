#GPIO LEDs
set_property PACKAGE_PIN AB8 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS15 [get_ports mmcm_lock]
set_property PACKAGE_PIN AA8 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS15 [get_ports init_calib_complete]

set_clock_groups -physically_exclusive -group [get_clocks -of_objects [get_pins *_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT0]] -group [get_clocks -of_objects [get_pins *_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT1]]
set_max_delay -datapath_only -from [get_pins -hier -filter {NAME =~ *rd_pntr_gc_reg[*]/C}] -to [get_pins -hier -filter {NAME =~ *gsync_stage[1].wr_stg_inst/Q_reg_reg[*]/D}] 4.000
set_max_delay -datapath_only -from [get_pins -hier -filter {NAME =~ *wr_pntr_gc_reg[*]/C}] -to [get_pins -hier -filter {NAME =~ *gsync_stage[1].rd_stg_inst/Q_reg_reg[*]/D}] 4.000

# System clock 200MHz
set_property PACKAGE_PIN AD12 [get_ports sys_diff_clock_clk_p]
set_property PACKAGE_PIN AD11 [get_ports sys_diff_clock_clk_n]
set_property IOSTANDARD LVDS [get_ports sys_diff_clock_clk_p]
set_property IOSTANDARD LVDS [get_ports sys_diff_clock_clk_n]

# PCI Express reset (perst) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN AD23 [get_ports perst_n]
set_property IOSTANDARD LVCMOS25 [get_ports perst_n]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN N8 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN N7 [get_ports {ref_clk_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_clk_p -waveform {0.000 5.000} [get_ports ref_clk_clk_p]

# System reset (CPU_RESET)
set_property PACKAGE_PIN AB7 [get_ports reset]
set_property IOSTANDARD LVCMOS15 [get_ports reset]

# MGT locations
set_property BEL GTXE2_CHANNEL [get_cells {*_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X0Y11 [get_cells {*_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN F5 [get_ports {pci_exp_rxn[0]}]
set_property PACKAGE_PIN F6 [get_ports {pci_exp_rxp[0]}]
set_property PACKAGE_PIN F1 [get_ports {pci_exp_txn[0]}]
set_property PACKAGE_PIN F2 [get_ports {pci_exp_txp[0]}]

set_property LOC PCIE_X0Y0 [get_cells *_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.pcie_top_i/pcie_7x_i/pcie_block_i]

set_false_path -to [get_pins *_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S*]

set_property BEL GTXE2_COMMON [get_cells {*_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[0].pipe_quad.gt_common_enabled.gt_common_int.gt_common_i/qpll_wrapper_i/gtx_common.gtxe2_common_i}]
set_property LOC GTXE2_COMMON_X0Y2 [get_cells {*_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[0].pipe_quad.gt_common_enabled.gt_common_int.gt_common_i/qpll_wrapper_i/gtx_common.gtxe2_common_i}]

