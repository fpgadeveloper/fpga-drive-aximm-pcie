#GPIO LEDs
set_property PACKAGE_PIN M26 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS33 [get_ports mmcm_lock]
set_property PACKAGE_PIN T24 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS33 [get_ports init_calib_complete]

set_clock_groups -physically_exclusive -group [get_clocks -of_objects [get_pins *_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT0]] -group [get_clocks -of_objects [get_pins *_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT1]]
set_max_delay -datapath_only -from [get_pins -hier -filter {NAME =~ *rd_pntr_gc_reg[*]/C}] -to [get_pins -hier -filter {NAME =~ *gsync_stage[1].wr_stg_inst/Q_reg_reg[*]/D}] 4.000
set_max_delay -datapath_only -from [get_pins -hier -filter {NAME =~ *wr_pntr_gc_reg[*]/C}] -to [get_pins -hier -filter {NAME =~ *gsync_stage[1].rd_stg_inst/Q_reg_reg[*]/D}] 4.000

# System clock 200MHz - LVDS on HR bank must be LVDS_25 even though power supply is 1.5V
set_property PACKAGE_PIN R3 [get_ports sys_diff_clock_clk_p]
set_property PACKAGE_PIN P3 [get_ports sys_diff_clock_clk_n]
set_property IOSTANDARD LVDS_25 [get_ports sys_diff_clock_clk_p]
set_property IOSTANDARD LVDS_25 [get_ports sys_diff_clock_clk_n]

# PCI Express reset (perst)
set_property PACKAGE_PIN D18 [get_ports perst[0]]
set_property IOSTANDARD LVCMOS25 [get_ports perst[0]]

# PCI Express reference clock 100MHz
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN AA13 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN AB13 [get_ports {ref_clk_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_clk_p -waveform {0.000 5.000} [get_ports ref_clk_clk_p]

# System reset
set_property PACKAGE_PIN U4 [get_ports reset]
set_property IOSTANDARD LVCMOS15 [get_ports reset]

# SFP MGT Clock select signals
set_property PACKAGE_PIN B26 [get_ports {sfp_mgt_clk_sel0[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {sfp_mgt_clk_sel0[0]}]
set_property PACKAGE_PIN C24 [get_ports {sfp_mgt_clk_sel1[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {sfp_mgt_clk_sel1[0]}]

# MGT locations
set_property PACKAGE_PIN AF13 [get_ports {pci_exp_rxn[0]}]
set_property PACKAGE_PIN AE13 [get_ports {pci_exp_rxp[0]}]
set_property PACKAGE_PIN AF9 [get_ports {pci_exp_txn[0]}]
set_property PACKAGE_PIN AE9 [get_ports {pci_exp_txp[0]}]

set_property PACKAGE_PIN AD14 [get_ports {pci_exp_rxn[1]}]
set_property PACKAGE_PIN AC14 [get_ports {pci_exp_rxp[1]}]
set_property PACKAGE_PIN AD8 [get_ports {pci_exp_txn[1]}]
set_property PACKAGE_PIN AC8 [get_ports {pci_exp_txp[1]}]

# PCIe integrated block
set_property LOC PCIE_X0Y0 [get_cells *_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.pcie_top_i/pcie_7x_i/pcie_block_i]

set_false_path -to [get_pins *_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S*]

set_property BEL GTPE2_COMMON [get_cells {*_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[0].pipe_quad.gt_common_enabled.gt_common_int.gt_common_i/qpll_wrapper_i/gtp_common.gtpe2_common_i}]
set_property LOC GTPE2_COMMON_X0Y0 [get_cells {*_i/axi_pcie_1/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[0].pipe_quad.gt_common_enabled.gt_common_int.gt_common_i/qpll_wrapper_i/gtp_common.gtpe2_common_i}]
