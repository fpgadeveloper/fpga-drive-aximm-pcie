#----------------------------------------------------------------------------------------
# Constraints for Opsero FPGA Drive FMC Gen4 ref design for VPK180 using 1x SSD
#----------------------------------------------------------------------------------------

# SSD1 PCI Express reset (perst_0)
set_property PACKAGE_PIN BV49 [get_ports {perst_0[0]}]; # LA00_CC_P
set_property IOSTANDARD LVCMOS15 [get_ports {perst_0[0]}]

# SSD1 PE Detect (pedet_0, not connected in the design)
# set_property PACKAGE_PIN BV50 [get_ports {pedet_0[0]}]; # LA00_CC_N
# set_property IOSTANDARD LVCMOS18 [get_ports {pedet_0[0]}]

# Disable signal for 3.3V power supply for SSD2 (disable_ssd2_pwr)
set_property PACKAGE_PIN CB49 [get_ports disable_ssd2_pwr]; # LA07_P
set_property IOSTANDARD LVCMOS15 [get_ports disable_ssd2_pwr]

##############################
# PCIe reference clock 100MHz
##############################

# SSD1 ref clock
set_property PACKAGE_PIN AT48 [get_ports {ref_clk_0_clk_p[0]}]; # GBTCLK0_M2C_P
set_property PACKAGE_PIN AT49 [get_ports {ref_clk_0_clk_n[0]}]; # GBTCLK0_M2C_N
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

############################
# SSD1 Gigabit transceivers
############################

set_property PACKAGE_PIN CD54 [get_ports {pci_exp_0_gtx_p[0]}]; # DP0_C2M_P
set_property PACKAGE_PIN CD55 [get_ports {pci_exp_0_gtx_n[0]}]; # DP0_C2M_N
set_property PACKAGE_PIN CB61 [get_ports {pci_exp_0_grx_p[0]}]; # DP0_M2C_P
set_property PACKAGE_PIN CB62 [get_ports {pci_exp_0_grx_n[0]}]; # DP0_M2C_N

set_property PACKAGE_PIN CD58 [get_ports {pci_exp_0_gtx_p[1]}]; # DP1_C2M_P
set_property PACKAGE_PIN CD59 [get_ports {pci_exp_0_gtx_n[1]}]; # DP1_C2M_N
set_property PACKAGE_PIN BY61 [get_ports {pci_exp_0_grx_p[1]}]; # DP1_M2C_P
set_property PACKAGE_PIN BY62 [get_ports {pci_exp_0_grx_n[1]}]; # DP1_M2C_N

set_property PACKAGE_PIN CC56 [get_ports {pci_exp_0_gtx_p[2]}]; # DP2_C2M_P
set_property PACKAGE_PIN CC57 [get_ports {pci_exp_0_gtx_n[2]}]; # DP2_C2M_N
set_property PACKAGE_PIN BW63 [get_ports {pci_exp_0_grx_p[2]}]; # DP2_M2C_P
set_property PACKAGE_PIN BW64 [get_ports {pci_exp_0_grx_n[2]}]; # DP2_M2C_N

set_property PACKAGE_PIN CB58 [get_ports {pci_exp_0_gtx_p[3]}]; # DP3_C2M_P
set_property PACKAGE_PIN CB59 [get_ports {pci_exp_0_gtx_n[3]}]; # DP3_C2M_N
set_property PACKAGE_PIN BV61 [get_ports {pci_exp_0_grx_p[3]}]; # DP3_M2C_P
set_property PACKAGE_PIN BV62 [get_ports {pci_exp_0_grx_n[3]}]; # DP3_M2C_N


##############################################################################
# Placement: keep the QDMA soft core next to its PCIE50 hard block
##############################################################################
# PCIE50_X1Y0 and GTYP_QUAD_X1Y0 sit in clock region X9Y1 (SLR0). Left to itself
# the placer spreads the ~90k-cell QDMA soft core (qdma_0) thinly along clock-
# region row Y1 from X2 to X9. The QDMA request engine (dma_pcie_rq / RQ_FIFO /
# rc_new, 13-15 LUT levels with high-fanout enables, ~73% route delay) then only
# met 250 MHz (qdma_0_axi_aclk) by a few ps, and the 500 MHz PIPE paths into the
# PCIE50E5 (phy_pclk/phy_coreclk, which the pcie_phy IP puts in the same
# CLOCK_DELAY_GROUP as the user clock, rooted at X5Y1) sat at +0.001 ns. Both
# needed the post-route phys_opt rescue (route_design -0.13..-0.16 ns) and the
# build closed at WNS 0.000..+0.001 ns.
# This hard pblock confines qdma_0 and qdma_support_0 to clock regions X6..X9
# of rows Y1..Y2, next to PCIE50_X1Y0 and the PL NoC NMU (the placer packs it
# into X6Y1..X9Y1); the router alone then closes at about +0.03 ns, no rescue.
# Must be hard (IS_SOFT FALSE): Vivado creates pblocks soft by default here and
# the placer then ignores most of the range. Do not add the SmartConnects to it:
# their PS-side (clk_pl_0) halves must stay near the CIPS (tried: -1.2 ns).
create_pblock pblock_qdma0
add_cells_to_pblock [get_pblocks pblock_qdma0] [get_cells [list fpgadrv_i/qdma_0 fpgadrv_i/qdma_support_0]]
resize_pblock [get_pblocks pblock_qdma0] -add {CLOCKREGION_X6Y1:CLOCKREGION_X9Y2}
set_property IS_SOFT FALSE [get_pblocks pblock_qdma0]
