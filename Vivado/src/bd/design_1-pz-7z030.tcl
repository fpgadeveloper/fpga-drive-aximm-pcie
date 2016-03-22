################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2015.4
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   puts "ERROR: This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."

   return 1
}

set design_name design_1

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

create_bd_design $design_name

current_bd_design $design_name

set parentCell [get_bd_cells /]

# Get object for parentCell
set parentObj [get_bd_cells $parentCell]
if { $parentObj == "" } {
   puts "ERROR: Unable to find parent cell <$parentCell>!"
   return
}

# Make sure parentObj is hier blk
set parentType [get_property TYPE $parentObj]
if { $parentType ne "hier" } {
   puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
   return
}

# Save current instance; Restore later
set oldCurInst [current_bd_instance .]

# Set parent object as current
current_bd_instance $parentObj

# Add the Processor System and apply board preset
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

# Configure the PS: Generate 200MHz clock, Enable HP0, Enable interrupts
startgroup
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {1} CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_USE_FABRIC_INTERRUPT {1} CONFIG.PCW_EN_CLK0_PORT {0} CONFIG.PCW_IRQ_F2P_INTR {1}] [get_bd_cells processing_system7_0]
endgroup

# Add the AXI Memory Mapped to PCIe Bridge IP
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie:2.7 axi_pcie_0
set_property -dict [list CONFIG.INCLUDE_RC {Root_Port_of_PCI_Express_Root_Complex} CONFIG.MAX_LINK_SPEED {5.0_GT/s} CONFIG.BAR0_SCALE {Gigabytes} CONFIG.DEVICE_ID {0x7012} CONFIG.BASE_CLASS_MENU {Bridge_device} CONFIG.SUB_CLASS_INTERFACE_MENU {InfiniBand_to_PCI_host_bridge} CONFIG.BAR0_SIZE {1} CONFIG.S_AXI_DATA_WIDTH {64} CONFIG.M_AXI_DATA_WIDTH {64}] [get_bd_cells axi_pcie_0]
endgroup

# Add port for PERST_N
startgroup
create_bd_port -dir I -type rst perst_n
connect_bd_net [get_bd_pins /axi_pcie_0/axi_aresetn] [get_bd_ports perst_n]
endgroup

# Add port for PCIe bus
startgroup
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_7x_mgt
connect_bd_intf_net [get_bd_intf_pins axi_pcie_0/pcie_7x_mgt] [get_bd_intf_ports pcie_7x_mgt]
endgroup

# Add constant to tie off /axi_pcie_0/INTX_MSI_Request
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells xlconstant_0]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins axi_pcie_0/INTX_MSI_Request]
endgroup

# Add differential buffer for the 100MHz PCIe reference clock
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 ref_clk_buf
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] [get_bd_cells ref_clk_buf]
connect_bd_net [get_bd_pins ref_clk_buf/IBUF_OUT] [get_bd_pins axi_pcie_0/REFCLK]
endgroup
startgroup
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk
connect_bd_intf_net [get_bd_intf_pins ref_clk_buf/CLK_IN_D] [get_bd_intf_ports ref_clk]
endgroup

# Add CDMA
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_0
set_property -dict [list CONFIG.C_M_AXI_DATA_WIDTH {128} CONFIG.C_INCLUDE_SG {0} CONFIG.C_M_AXI_MAX_BURST_LEN {4}] [get_bd_cells axi_cdma_0]
endgroup

# Add interrupt concat
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
set_property -dict [list CONFIG.NUM_PORTS {2}] [get_bd_cells xlconcat_0]
endgroup

# Add AXI Interconnect 0
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_0]
endgroup
connect_bd_intf_net [get_bd_intf_pins axi_pcie_0/M_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]

# Add AXI Interconnect 1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {3}] [get_bd_cells axi_interconnect_1]
endgroup
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins axi_pcie_0/S_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_1/M01_AXI] [get_bd_intf_pins axi_pcie_0/S_AXI_CTL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_1/M02_AXI] [get_bd_intf_pins axi_cdma_0/S_AXI_LITE]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_1/S00_AXI] [get_bd_intf_pins processing_system7_0/M_AXI_GP0]

# Add AXI Interconnect 2
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_2
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {2}] [get_bd_cells axi_interconnect_2]
endgroup
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_2/M00_AXI] [get_bd_intf_pins axi_interconnect_0/S01_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_2/M01_AXI] [get_bd_intf_pins axi_interconnect_1/S01_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_cdma_0/M_AXI] [get_bd_intf_pins axi_interconnect_2/S00_AXI]

# Add Processor System Reset 0
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
endgroup
connect_bd_net [get_bd_ports perst_n] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins axi_pcie_0/axi_ctl_aclk_out]
connect_bd_net [get_bd_pins proc_sys_reset_0/dcm_locked] [get_bd_pins axi_pcie_0/mmcm_lock]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_1/M01_ARESETN]
connect_bd_net [get_bd_pins axi_interconnect_1/M01_ACLK] [get_bd_pins axi_pcie_0/axi_ctl_aclk_out]

# Add Processor System Reset 1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1
endgroup
connect_bd_net [get_bd_pins proc_sys_reset_1/slowest_sync_clk] [get_bd_pins axi_pcie_0/axi_aclk_out]
connect_bd_net [get_bd_ports perst_n] [get_bd_pins proc_sys_reset_1/ext_reset_in]
connect_bd_net [get_bd_pins proc_sys_reset_1/dcm_locked] [get_bd_pins axi_pcie_0/mmcm_lock]
connect_bd_net [get_bd_pins proc_sys_reset_1/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/interconnect_aresetn] [get_bd_pins axi_interconnect_1/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/interconnect_aresetn] [get_bd_pins axi_interconnect_2/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_0/S01_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_1/S00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_1/S01_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_1/M00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_1/M02_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_cdma_0/s_axi_lite_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_2/S00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_2/M00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_2/M01_ARESETN]

# Connect /axi_pcie_0/axi_aclk_out to all clock inputs
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_0/S01_ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_1/ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_1/S00_ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_1/S01_ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_1/M00_ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_1/M02_ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_2/ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_2/S00_ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_2/M00_ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_interconnect_2/M01_ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_cdma_0/m_axi_aclk]
connect_bd_net [get_bd_pins axi_pcie_0/axi_aclk_out] [get_bd_pins axi_cdma_0/s_axi_lite_aclk]

# Connect interrupts
connect_bd_net [get_bd_pins axi_pcie_0/interrupt_out] [get_bd_pins xlconcat_0/In0]
connect_bd_net [get_bd_pins axi_cdma_0/cdma_introut] [get_bd_pins xlconcat_0/In1]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins processing_system7_0/IRQ_F2P]

# Assign addresses
create_bd_addr_seg -range 1G -offset 0x00000000 [get_bd_addr_spaces axi_pcie_0/M_AXI] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG1
create_bd_addr_seg -range 1G -offset 0x00000000 [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG1
create_bd_addr_seg -range 256M -offset 0x60000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_pcie_0/S_AXI/BAR0] SEG2
create_bd_addr_seg -range 256M -offset 0x60000000 [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs axi_pcie_0/S_AXI/BAR0] SEG2
create_bd_addr_seg -range 64M -offset 0x50000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_pcie_0/S_AXI_CTL/CTL0] SEG3
create_bd_addr_seg -range 64M -offset 0x50000000 [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs axi_pcie_0/S_AXI_CTL/CTL0] SEG3
create_bd_addr_seg -range 64K -offset 0x7E200000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_cdma_0/S_AXI_LITE/Reg] SEG4
create_bd_addr_seg -range 64K -offset 0x7E200000 [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs axi_cdma_0/S_AXI_LITE/Reg] SEG4

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design
