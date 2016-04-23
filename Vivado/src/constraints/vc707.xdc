#GPIO LEDs
set_property PACKAGE_PIN AM39 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]
set_property PACKAGE_PIN AN39 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS18 [get_ports init_calib_complete]

set_clock_groups -physically_exclusive -group [get_clocks -of_objects [get_pins design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT0]] -group [get_clocks -of_objects [get_pins design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT1]]
set_max_delay -datapath_only -from [get_pins -hier -filter {NAME =~ *rd_pntr_gc_reg[*]/C}] -to [get_pins -hier -filter {NAME =~ *gsync_stage[1].wr_stg_inst/Q_reg_reg[*]/D}] 4.000
set_max_delay -datapath_only -from [get_pins -hier -filter {NAME =~ *wr_pntr_gc_reg[*]/C}] -to [get_pins -hier -filter {NAME =~ *gsync_stage[1].rd_stg_inst/Q_reg_reg[*]/D}] 4.000

# System clock 200MHz
set_property PACKAGE_PIN E19 [get_ports sys_diff_clock_clk_p]
set_property PACKAGE_PIN E18 [get_ports sys_diff_clock_clk_n]
set_property IOSTANDARD LVDS [get_ports sys_diff_clock_clk_p]
set_property IOSTANDARD LVDS [get_ports sys_diff_clock_clk_n]

# PCI Express reset (perst)
set_property PACKAGE_PIN AV35 [get_ports perst_n]
set_property IOSTANDARD LVCMOS18 [get_ports perst_n]

# PCI Express reference clock 100MHz
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN AB8 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN AB7 [get_ports {ref_clk_clk_n[0]}]

# System reset (CPU_RESET)
set_property PACKAGE_PIN AV40 [get_ports reset]
set_property IOSTANDARD LVCMOS18 [get_ports reset]

# MGT locations
set_property BEL GTXE2_CHANNEL [get_cells {design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X1Y11 [get_cells {design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN W1 [get_ports {pci_exp_txn[0]}]
set_property PACKAGE_PIN Y3 [get_ports {pci_exp_rxn[0]}]
set_property PACKAGE_PIN Y4 [get_ports {pci_exp_rxp[0]}]
set_property PACKAGE_PIN W2 [get_ports {pci_exp_txp[0]}]
set_property BEL GTXE2_CHANNEL [get_cells {design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X1Y10 [get_cells {design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN AA1 [get_ports {pci_exp_txn[1]}]
set_property PACKAGE_PIN AA5 [get_ports {pci_exp_rxn[1]}]
set_property PACKAGE_PIN AA6 [get_ports {pci_exp_rxp[1]}]
set_property PACKAGE_PIN AA2 [get_ports {pci_exp_txp[1]}]
set_property BEL GTXE2_CHANNEL [get_cells {design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X1Y9 [get_cells {design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN AC1 [get_ports {pci_exp_txn[2]}]
set_property PACKAGE_PIN AB3 [get_ports {pci_exp_rxn[2]}]
set_property PACKAGE_PIN AB4 [get_ports {pci_exp_rxp[2]}]
set_property PACKAGE_PIN AC2 [get_ports {pci_exp_txp[2]}]
set_property BEL GTXE2_CHANNEL [get_cells {design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X1Y8 [get_cells {design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN AE1 [get_ports {pci_exp_txn[3]}]
set_property PACKAGE_PIN AC5 [get_ports {pci_exp_rxn[3]}]
set_property PACKAGE_PIN AC6 [get_ports {pci_exp_rxp[3]}]
set_property PACKAGE_PIN AE2 [get_ports {pci_exp_txp[3]}]

set_property BEL PCIE_2_1 [get_cells design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.pcie_top_i/pcie_7x_i/pcie_block_i]
set_property LOC PCIE_X1Y0 [get_cells design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.pcie_top_i/pcie_7x_i/pcie_block_i]

set_false_path -to [get_pins design_1_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S*]

