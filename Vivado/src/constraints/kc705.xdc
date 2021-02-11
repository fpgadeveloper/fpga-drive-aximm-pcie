#GPIO LEDs
set_property PACKAGE_PIN AB8 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS15 [get_ports mmcm_lock]
set_property PACKAGE_PIN AA8 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS15 [get_ports init_calib_complete]
set_property PACKAGE_PIN AC9 [get_ports user_link_up_0]
set_property IOSTANDARD LVCMOS15 [get_ports user_link_up_0]
#set_property PACKAGE_PIN AB9 [get_ports GPIO_LED_3_LS]
#set_property IOSTANDARD LVCMOS15 [get_ports GPIO_LED_3_LS]
#set_property PACKAGE_PIN AE26 [get_ports GPIO_LED_4_LS]
#set_property IOSTANDARD LVCMOS25 [get_ports GPIO_LED_4_LS]
#set_property PACKAGE_PIN G19 [get_ports GPIO_LED_5_LS]
#set_property IOSTANDARD LVCMOS25 [get_ports GPIO_LED_5_LS]
#set_property PACKAGE_PIN E18 [get_ports GPIO_LED_6_LS]
#set_property IOSTANDARD LVCMOS25 [get_ports GPIO_LED_6_LS]
#set_property PACKAGE_PIN F16 [get_ports GPIO_LED_7_LS]
#set_property IOSTANDARD LVCMOS25 [get_ports GPIO_LED_7_LS]

# PCI Express reset (perst)
set_property PACKAGE_PIN G25 [get_ports perst_n]
set_property IOSTANDARD LVCMOS25 [get_ports perst_n]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports ref_clk_0_clk_p]
set_property PACKAGE_PIN U8 [get_ports ref_clk_0_clk_p]
set_property PACKAGE_PIN U7 [get_ports ref_clk_0_clk_n]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

# System reset
set_property PACKAGE_PIN AB7 [get_ports reset]
set_property IOSTANDARD LVCMOS15 [get_ports reset]

set_property LOC GTXE2_CHANNEL_X0Y7 [get_cells {*_i/axi_pcie_0/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]

# MGT locations
set_property PACKAGE_PIN M5 [get_ports {pci_exp_0_rxn[0]}]
set_property PACKAGE_PIN M6 [get_ports {pci_exp_0_rxp[0]}]
set_property PACKAGE_PIN P5 [get_ports {pci_exp_0_rxn[1]}]
set_property PACKAGE_PIN P6 [get_ports {pci_exp_0_rxp[1]}]
set_property PACKAGE_PIN R3 [get_ports {pci_exp_0_rxn[2]}]
set_property PACKAGE_PIN R4 [get_ports {pci_exp_0_rxp[2]}]
set_property PACKAGE_PIN T5 [get_ports {pci_exp_0_rxn[3]}]
set_property PACKAGE_PIN T6 [get_ports {pci_exp_0_rxp[3]}]
set_property PACKAGE_PIN L3 [get_ports {pci_exp_0_txn[0]}]
set_property PACKAGE_PIN L4 [get_ports {pci_exp_0_txp[0]}]
set_property PACKAGE_PIN M1 [get_ports {pci_exp_0_txn[1]}]
set_property PACKAGE_PIN M2 [get_ports {pci_exp_0_txp[1]}]
set_property PACKAGE_PIN N3 [get_ports {pci_exp_0_txn[2]}]
set_property PACKAGE_PIN N4 [get_ports {pci_exp_0_txp[2]}]
set_property PACKAGE_PIN P1 [get_ports {pci_exp_0_txn[3]}]
set_property PACKAGE_PIN P2 [get_ports {pci_exp_0_txp[3]}]

set_property LOC PCIE_X0Y0 [get_cells *_i/axi_pcie_0/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.pcie_top_i/pcie_7x_i/pcie_block_i]

set_false_path -to [get_pins *_i/axi_pcie_0/inst/comp_axi_enhanced_pcie/comp_enhanced_core_top_wrap/axi_pcie_enhanced_core_top_i/pcie_7x_v2_0_2_inst/pcie_top_with_gt_top.gt_ges.gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S*]

set_property PACKAGE_PIN AA8 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS15 [get_ports init_calib_complete]

set_property DCI_CASCADE {32 34} [get_iobanks 33]

# Configuration via Quad SPI settings for KC705
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
#set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
#set_property CONFIG_VOLTAGE 2.8 [current_design]
#set_property CFGBVS GND [current_design]
#set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
#set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]

# Configuration via BPI flash for KC705
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE DISABLE [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CONFIG_MODE BPI16 [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]

