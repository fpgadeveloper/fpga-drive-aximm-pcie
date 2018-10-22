# PCI Express reset (perst_0) - IOSTANDARD determined by VADJ which is fixed to 1.8V on KCU105
set_property PACKAGE_PIN H11 [get_ports {perst_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# PCI Express reset (perst_1) - IOSTANDARD determined by VADJ which is fixed to 1.8V on KCU105
set_property PACKAGE_PIN L12 [get_ports {perst_1[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst_1[0]}]

# PEDET_0 - G11 - IOSTANDARD determined by VADJ which is fixed to 1.8V on KCU105
# PEDET_1 - K12 - IOSTANDARD determined by VADJ which is fixed to 1.8V on KCU105

# Disable signal for 3.3V power supply for SSD2
set_property PACKAGE_PIN F8 [get_ports disable_ssd2_pwr]
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
set_property PACKAGE_PIN K6 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN K5 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

set_property PACKAGE_PIN H6 [get_ports {ref_clk_1_clk_p[0]}]
set_property PACKAGE_PIN H5 [get_ports {ref_clk_1_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_1_clk_p -waveform {0.000 5.000} [get_ports ref_clk_1_clk_p]

# MGT locations
set_property LOC GTHE3_CHANNEL_X0Y16 [get_cells {*_i/axi_pcie3_0/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_0_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_0_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[4].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]
set_property LOC GTHE3_CHANNEL_X0Y17 [get_cells {*_i/axi_pcie3_0/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_0_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_0_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[4].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[1].GTHE3_CHANNEL_PRIM_INST}]
set_property LOC GTHE3_CHANNEL_X0Y18 [get_cells {*_i/axi_pcie3_0/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_0_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_0_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[4].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[2].GTHE3_CHANNEL_PRIM_INST}]
set_property LOC GTHE3_CHANNEL_X0Y19 [get_cells {*_i/axi_pcie3_0/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_0_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_0_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[4].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[3].GTHE3_CHANNEL_PRIM_INST}]

set_property LOC GTHE3_CHANNEL_X0Y12 [get_cells {*_i/axi_pcie3_1/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_1_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_1_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[3].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]
set_property LOC GTHE3_CHANNEL_X0Y11 [get_cells {*_i/axi_pcie3_1/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_1_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_1_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[3].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[1].GTHE3_CHANNEL_PRIM_INST}]
set_property LOC GTHE3_CHANNEL_X0Y13 [get_cells {*_i/axi_pcie3_1/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_1_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_1_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[3].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[2].GTHE3_CHANNEL_PRIM_INST}]
set_property LOC GTHE3_CHANNEL_X0Y14 [get_cells {*_i/axi_pcie3_1/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_1_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_1_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[3].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[1].GTHE3_CHANNEL_PRIM_INST}]
set_property LOC GTHE3_CHANNEL_X0Y15 [get_cells {*_i/axi_pcie3_1/inst/pcie3_ip_i/inst/gt_top_i/gt_wizard.gtwizard_top_i/*_axi_pcie3_1_0_pcie3_ip_gt_i/inst/gen_gtwizard_gthe3_top.*_axi_pcie3_1_0_pcie3_ip_gt_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[3].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[3].GTHE3_CHANNEL_PRIM_INST}]

# KCU105 HPC transceivers for SSD1 are best aligned with PCIE_X0Y2
set_property LOC PCIE_3_1_X0Y2 [get_cells *_i/axi_pcie3_0/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst]

# KCU105 HPC transceivers for SSD2 are best aligned with PCIE_X0Y1
set_property LOC PCIE_3_1_X0Y1 [get_cells *_i/axi_pcie3_1/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst]

# Configuration via Dual Quad SPI settings for KCU105
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
