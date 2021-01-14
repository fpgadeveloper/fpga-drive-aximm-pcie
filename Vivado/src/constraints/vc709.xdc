#GPIO LEDs
set_property PACKAGE_PIN AM39 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]
set_property PACKAGE_PIN AN39 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS18 [get_ports init_calib_complete]
set_property PACKAGE_PIN AR37 [get_ports user_link_up_0]
set_property IOSTANDARD LVCMOS18 [get_ports user_link_up_0]
#set_property PACKAGE_PIN AT37 [get_ports user_led_3]
#set_property IOSTANDARD LVCMOS18 [get_ports user_led_3]

# PCI Express reset (perst)
set_property PACKAGE_PIN AV35 [get_ports perst_n]
set_property IOSTANDARD LVCMOS18 [get_ports perst_n]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN AB8 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN AB7 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

# MGT locations
set_property LOC GTHE2_CHANNEL_X1Y23 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property LOC GTHE2_CHANNEL_X1Y22 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property LOC GTHE2_CHANNEL_X1Y21 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property LOC GTHE2_CHANNEL_X1Y20 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gth_channel.gthe2_channel_i}]

# PCIe integrated block
set_property BEL PCIE_3_0 [get_cells *_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/PCIE_3_0_i]
set_property LOC PCIE3_X0Y1 [get_cells *_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/PCIE_3_0_i]

set_property LOC RAMB36_X12Y56 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/replay_buffer/U0/RAMB36E1[1].u_buffer}]
set_property LOC RAMB36_X12Y55 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/replay_buffer/U0/RAMB36E1[0].u_buffer}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[7].u_fifo}]
set_property LOC RAMB18_X12Y103 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[7].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[6].u_fifo}]
set_property LOC RAMB18_X12Y102 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[6].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[5].u_fifo}]
set_property LOC RAMB18_X12Y101 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[5].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[4].u_fifo}]
set_property LOC RAMB18_X12Y100 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[4].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[3].u_fifo}]
set_property LOC RAMB18_X12Y99 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[3].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[2].u_fifo}]
set_property LOC RAMB18_X12Y98 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[2].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[1].u_fifo}]
set_property LOC RAMB18_X12Y97 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[1].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[0].u_fifo}]
set_property LOC RAMB18_X12Y96 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[0].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[3].u_fifo}]
set_property LOC RAMB18_X12Y95 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[3].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[2].u_fifo}]
set_property LOC RAMB18_X12Y94 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[2].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[1].u_fifo}]
set_property LOC RAMB18_X12Y93 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[1].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[0].u_fifo}]
set_property LOC RAMB18_X12Y92 [get_cells {*_i/axi_pcie_0/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[0].u_fifo}]

# Configuration via BPI flash for VC709
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE DISABLE [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CONFIG_MODE BPI16 [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

