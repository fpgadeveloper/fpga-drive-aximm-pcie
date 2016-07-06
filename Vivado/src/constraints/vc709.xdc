#GPIO LEDs
set_property PACKAGE_PIN AM39 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]
set_property PACKAGE_PIN AN39 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS18 [get_ports init_calib_complete]

# System clock 200MHz
set_property PACKAGE_PIN G18 [get_ports sys_diff_clock_clk_n]
set_property PACKAGE_PIN H19 [get_ports sys_diff_clock_clk_p]
set_property IOSTANDARD LVDS [get_ports sys_diff_clock_clk_p]
set_property IOSTANDARD LVDS [get_ports sys_diff_clock_clk_n]

# PCI Express reset (perst)
set_property PACKAGE_PIN AV35 [get_ports perst_n]
set_property IOSTANDARD LVCMOS18 [get_ports perst_n]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN AB8 [get_ports {ref_clk_clk_p[0]}]
set_property PACKAGE_PIN AB7 [get_ports {ref_clk_clk_n[0]}]

# System reset (CPU_RESET)
set_property PACKAGE_PIN AV40 [get_ports reset]
set_property IOSTANDARD LVCMOS18 [get_ports reset]

# MGT locations
set_property LOC GTHE2_CHANNEL_X1Y23 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN Y4 [get_ports {pci_exp_rxp[0]}]
set_property PACKAGE_PIN Y3 [get_ports {pci_exp_rxn[0]}]
set_property PACKAGE_PIN W1 [get_ports {pci_exp_txn[0]}]
set_property PACKAGE_PIN W2 [get_ports {pci_exp_txp[0]}]

set_property LOC GTHE2_CHANNEL_X1Y22 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN AA6 [get_ports {pci_exp_rxp[1]}]
set_property PACKAGE_PIN AA5 [get_ports {pci_exp_rxn[1]}]
set_property PACKAGE_PIN AA1 [get_ports {pci_exp_txn[1]}]
set_property PACKAGE_PIN AA2 [get_ports {pci_exp_txp[1]}]

set_property LOC GTHE2_CHANNEL_X1Y21 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN AB4 [get_ports {pci_exp_rxp[2]}]
set_property PACKAGE_PIN AB3 [get_ports {pci_exp_rxn[2]}]
set_property PACKAGE_PIN AC1 [get_ports {pci_exp_txn[2]}]
set_property PACKAGE_PIN AC2 [get_ports {pci_exp_txp[2]}]

set_property LOC GTHE2_CHANNEL_X1Y20 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gth_channel.gthe2_channel_i}]
set_property PACKAGE_PIN AE1 [get_ports {pci_exp_txn[3]}]
set_property PACKAGE_PIN AC6 [get_ports {pci_exp_rxp[3]}]
set_property PACKAGE_PIN AC5 [get_ports {pci_exp_rxn[3]}]
set_property PACKAGE_PIN AE2 [get_ports {pci_exp_txp[3]}]

# PCIe integrated block
set_property BEL PCIE_3_0 [get_cells *_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/PCIE_3_0_i]
set_property LOC PCIE3_X0Y1 [get_cells *_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/PCIE_3_0_i]

set_property LOC RAMB36_X12Y56 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/replay_buffer/U0/RAMB36E1[1].u_buffer}]
set_property LOC RAMB36_X12Y55 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/replay_buffer/U0/RAMB36E1[0].u_buffer}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[7].u_fifo}]
set_property LOC RAMB18_X12Y103 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[7].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[6].u_fifo}]
set_property LOC RAMB18_X12Y102 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[6].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[5].u_fifo}]
set_property LOC RAMB18_X12Y101 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[5].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[4].u_fifo}]
set_property LOC RAMB18_X12Y100 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[4].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[3].u_fifo}]
set_property LOC RAMB18_X12Y99 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[3].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[2].u_fifo}]
set_property LOC RAMB18_X12Y98 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[2].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[1].u_fifo}]
set_property LOC RAMB18_X12Y97 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[1].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[0].u_fifo}]
set_property LOC RAMB18_X12Y96 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_500MHz_OR_NO_DECODE_LOGIC.RAMB18E1[0].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[3].u_fifo}]
set_property LOC RAMB18_X12Y95 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[3].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[2].u_fifo}]
set_property LOC RAMB18_X12Y94 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[2].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[1].u_fifo}]
set_property LOC RAMB18_X12Y93 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[1].u_fifo}]
set_property BEL RAMB18E1 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[0].u_fifo}]
set_property LOC RAMB18_X12Y92 [get_cells {*_i/axi_pcie_1/inst/pcie3_ip_i/inst/pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[0].u_fifo}]


