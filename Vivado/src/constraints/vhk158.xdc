#----------------------------------------------------------------------------------------
# Constraints for Opsero FPGA Drive FMC Gen4 ref design for VHK158 using 1x SSD
#----------------------------------------------------------------------------------------

# SSD1 PCI Express reset (perst_0)
set_property PACKAGE_PIN BG58 [get_ports {perst_0[0]}]; # LA00_CC_P
set_property IOSTANDARD LVCMOS15 [get_ports {perst_0[0]}]

# SSD1 PE Detect (pedet_0, not connected in the design)
# set_property PACKAGE_PIN BG59 [get_ports {pedet_0[0]}]; # LA00_CC_N
# set_property IOSTANDARD LVCMOS15 [get_ports {pedet_0[0]}]

# Disable signal for 3.3V power supply for SSD2 (disable_ssd2_pwr)
set_property PACKAGE_PIN BJ60 [get_ports disable_ssd2_pwr]; # LA07_P
set_property IOSTANDARD LVCMOS15 [get_ports disable_ssd2_pwr]

##############################
# PCIe reference clock 100MHz
##############################

# SSD1 ref clock
set_property PACKAGE_PIN BF47 [get_ports {ref_clk_0_clk_p[0]}]; # GBTCLK0_M2C_P
set_property PACKAGE_PIN BF48 [get_ports {ref_clk_0_clk_n[0]}]; # GBTCLK0_M2C_N
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

############################
# SSD1 Gigabit transceivers
############################

set_property PACKAGE_PIN BE53 [get_ports {pci_exp_0_gtx_p[0]}]; # DP0_C2M_P
set_property PACKAGE_PIN BE54 [get_ports {pci_exp_0_gtx_n[0]}]; # DP0_C2M_N
set_property PACKAGE_PIN BE58 [get_ports {pci_exp_0_grx_p[0]}]; # DP0_M2C_P
set_property PACKAGE_PIN BE59 [get_ports {pci_exp_0_grx_n[0]}]; # DP0_M2C_N

set_property PACKAGE_PIN BD55 [get_ports {pci_exp_0_gtx_p[1]}]; # DP1_C2M_P
set_property PACKAGE_PIN BD56 [get_ports {pci_exp_0_gtx_n[1]}]; # DP1_C2M_N
set_property PACKAGE_PIN BD60 [get_ports {pci_exp_0_grx_p[1]}]; # DP1_M2C_P
set_property PACKAGE_PIN BD61 [get_ports {pci_exp_0_grx_n[1]}]; # DP1_M2C_N

set_property PACKAGE_PIN BD51 [get_ports {pci_exp_0_gtx_p[2]}]; # DP2_C2M_P
set_property PACKAGE_PIN BD52 [get_ports {pci_exp_0_gtx_n[2]}]; # DP2_C2M_N
set_property PACKAGE_PIN BC58 [get_ports {pci_exp_0_grx_p[2]}]; # DP2_M2C_P
set_property PACKAGE_PIN BC59 [get_ports {pci_exp_0_grx_n[2]}]; # DP2_M2C_N

set_property PACKAGE_PIN BC53 [get_ports {pci_exp_0_gtx_p[3]}]; # DP3_C2M_P
set_property PACKAGE_PIN BC54 [get_ports {pci_exp_0_gtx_n[3]}]; # DP3_C2M_N
set_property PACKAGE_PIN BB60 [get_ports {pci_exp_0_grx_p[3]}]; # DP3_M2C_P
set_property PACKAGE_PIN BB61 [get_ports {pci_exp_0_grx_n[3]}]; # DP3_M2C_N


##############################################
# Floorplan: QDMA soft IP next to PCIE50_X1Y0
##############################################
# The PCIE5 root port (PCIE50_X1Y0 + GTYP_QUAD_X1Y0) sits in clock region X9Y1. Without
# a floorplan the placer strings the QDMA soft IP (~36k LUT / 38k FF) out along row Y1
# from X1 to X9 (row Y0 has no fabric, row Y2 stays empty) and roots the 250 MHz
# qdma_0_axi_aclk tree in X5Y1. The 15-LUT-level request-engine paths
# (REQ_EN.dma_pcie_req/dma_pcie_rq, RQ_FIFO) then lose ~0.23 ns to clock skew and only
# close at 0.000 ns after post-route phys_opt.
# Attract the QDMA soft logic to the 2x2 clock regions beside the PCIE block. This pblock
# is deliberately left SOFT (the Versal default for this clock-region pblock): the placer
# may spill into X7Y1. A hard pblock (IS_SOFT FALSE) was tried and is worse (WNS -0.025,
# longer routes inside the 2x2 regions); the soft one plus the clock root below lets the
# design meet timing at route_design instead of relying on post-route phys_opt...
create_pblock pblock_qdma_0
add_cells_to_pblock [get_pblocks pblock_qdma_0] [get_cells fpgadrv_i/qdma_0]
resize_pblock [get_pblocks pblock_qdma_0] -add {CLOCKREGION_X8Y1:CLOCKREGION_X9Y2}
# ...and root the PCIe clocks (CLOCK_DELAY_GROUP PCIE_CDG: pclk, coreclk and the user
# clock = qdma_0_axi_aclk) in X9Y1 instead of the placer's centroid X5Y1.
# (-quiet: the BUFG_GTs are inside the out-of-context PHY IP, invisible to top-level synthesis)
set_property -quiet USER_CLOCK_ROOT X9Y1 [get_nets -quiet -of [get_pins -quiet -filter {REF_PIN_NAME=~O} -of [get_cells -quiet -hier -filter {NAME =~ fpgadrv_i/qdma_support_0/pcie_phy/*/phy_clk_i/bufg_gt_*}]]]
