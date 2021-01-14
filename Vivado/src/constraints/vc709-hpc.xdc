#GPIO LEDs
set_property PACKAGE_PIN AM39 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]
set_property PACKAGE_PIN AN39 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS18 [get_ports init_calib_complete]
set_property PACKAGE_PIN AR37 [get_ports user_link_up_0]
set_property IOSTANDARD LVCMOS18 [get_ports user_link_up_0]
#set_property PACKAGE_PIN AT37 [get_ports user_led_3]
#set_property IOSTANDARD LVCMOS18 [get_ports user_led_3]

# PCI Express reset (perst) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN K39 [get_ports perst_0[0]]
set_property IOSTANDARD LVCMOS18 [get_ports perst_0[0]]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN G10 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN G9 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

# MGT locations
set_property LOC GTHE2_CHANNEL_X1Y36 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property LOC GTHE2_CHANNEL_X1Y37 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property LOC GTHE2_CHANNEL_X1Y38 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property LOC GTHE2_CHANNEL_X1Y39 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gth_channel.gthe2_channel_i}]

# PCIe integrated block
set_property BEL PCIE_3_0 [get_cells *_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/PCIE_3_0_i]
set_property LOC PCIE3_X0Y2 [get_cells *_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/PCIE_3_0_i]


# Configuration via BPI flash for VC709
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE DISABLE [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CONFIG_MODE BPI16 [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

