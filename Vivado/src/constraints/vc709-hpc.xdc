#GPIO LEDs
set_property PACKAGE_PIN AM39 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]
set_property PACKAGE_PIN AN39 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS18 [get_ports init_calib_complete]

# System clock 200MHz
set_property PACKAGE_PIN H19 [get_ports sys_diff_clock_clk_p]
set_property PACKAGE_PIN G18 [get_ports sys_diff_clock_clk_n]
set_property IOSTANDARD LVDS [get_ports sys_diff_clock_clk_p]
set_property IOSTANDARD LVDS [get_ports sys_diff_clock_clk_n]

# PCI Express reset (perst) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN K39 [get_ports perst_n]
set_property IOSTANDARD LVCMOS18 [get_ports perst_n]

# PCI Express reference clock 100MHz
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN G10 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN G9 [get_ports {ref_clk_clk_n[0]}]

# System reset (CPU_RESET)
set_property PACKAGE_PIN AV40 [get_ports reset]
set_property IOSTANDARD LVCMOS18 [get_ports reset]

# MGT locations
set_property LOC GTHE2_CHANNEL_X1Y36 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN D7 [get_ports {pci_exp_rxn[0]}]
set_property PACKAGE_PIN D8 [get_ports {pci_exp_rxp[0]}]
set_property PACKAGE_PIN E1 [get_ports {pci_exp_txn[0]}]
set_property PACKAGE_PIN E2 [get_ports {pci_exp_txp[0]}]

set_property LOC GTHE2_CHANNEL_X1Y37 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN C5 [get_ports {pci_exp_rxn[1]}]
set_property PACKAGE_PIN C6 [get_ports {pci_exp_rxp[1]}]
set_property PACKAGE_PIN D3 [get_ports {pci_exp_txn[1]}]
set_property PACKAGE_PIN D4 [get_ports {pci_exp_txp[1]}]

set_property LOC GTHE2_CHANNEL_X1Y38 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN B7 [get_ports {pci_exp_rxn[2]}]
set_property PACKAGE_PIN B8 [get_ports {pci_exp_rxp[2]}]
set_property PACKAGE_PIN C1 [get_ports {pci_exp_txn[2]}]
set_property PACKAGE_PIN C2 [get_ports {pci_exp_txp[2]}]

set_property LOC GTHE2_CHANNEL_X1Y39 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN A5 [get_ports {pci_exp_rxn[3]}]
set_property PACKAGE_PIN A6 [get_ports {pci_exp_rxp[3]}]
set_property PACKAGE_PIN B3 [get_ports {pci_exp_txn[3]}]
set_property PACKAGE_PIN B4 [get_ports {pci_exp_txp[3]}]

# PCIe integrated block
set_property BEL PCIE_3_0 [get_cells design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/PCIE_3_0_i]
set_property LOC PCIE3_X0Y2 [get_cells design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/PCIE_3_0_i]


set_property LOC RAMB36_X12Y84 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/replay_buffer/U0/RAMB36E1[1].u_buffer}]
set_property LOC RAMB36_X12Y83 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/replay_buffer/U0/RAMB36E1[0].u_buffer}]
set_property BEL RAMB18E1 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[4].u_fifo}]
set_property LOC RAMB18_X12Y160 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[4].u_fifo}]
set_property BEL RAMB18E1 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[5].u_fifo}]
set_property LOC RAMB18_X12Y161 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[5].u_fifo}]
set_property BEL RAMB18E1 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[6].u_fifo}]
set_property LOC RAMB18_X12Y162 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[6].u_fifo}]
set_property BEL RAMB18E1 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[7].u_fifo}]
set_property LOC RAMB18_X12Y163 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[7].u_fifo}]
set_property BEL RAMB18E1 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[3].u_fifo}]
set_property LOC RAMB18_X12Y159 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[3].u_fifo}]
set_property BEL RAMB18E1 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[2].u_fifo}]
set_property LOC RAMB18_X12Y158 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[2].u_fifo}]
set_property BEL RAMB18E1 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[1].u_fifo}]
set_property LOC RAMB18_X12Y157 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[1].u_fifo}]
set_property BEL RAMB18E1 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[0].u_fifo}]
set_property LOC RAMB18_X12Y156 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[0].u_fifo}]
set_property BEL RAMB18E1 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[3].u_fifo}]
set_property LOC RAMB18_X12Y153 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[3].u_fifo}]
set_property BEL RAMB18E1 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[2].u_fifo}]
set_property LOC RAMB18_X12Y152 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[2].u_fifo}]
set_property BEL RAMB18E1 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[1].u_fifo}]
set_property LOC RAMB18_X12Y151 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[1].u_fifo}]
set_property BEL RAMB18E1 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[0].u_fifo}]
set_property LOC RAMB18_X12Y150 [get_cells {design_1_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[0].u_fifo}]
