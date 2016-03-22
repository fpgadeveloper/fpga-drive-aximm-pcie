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

# Hierarchical cell: microblaze_1_local_memory
proc create_hier_cell_microblaze_1_local_memory { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_microblaze_1_local_memory() - Empty argument(s)!"
     return
  }

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

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier microblaze_1_local_memory]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB

  # Create pins
  create_bd_pin -dir I LMB_Clk
  create_bd_pin -dir I -from 0 -to 0 LMB_Rst

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property -dict [ list CONFIG.C_ECC {0}  ] $dlmb_bram_if_cntlr

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property -dict [ list CONFIG.C_ECC {0}  ] $ilmb_bram_if_cntlr

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 lmb_bram ]
  set_property -dict [ list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.use_bram_block {BRAM_Controller}  ] $lmb_bram

  # Create interface connections
  connect_bd_intf_net -intf_net microblaze_1_dlmb_bus [get_bd_intf_pins dlmb_v10/LMB_Sl_0] [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB]
  connect_bd_intf_net -intf_net microblaze_1_ilmb_bus [get_bd_intf_pins ilmb_v10/LMB_Sl_0] [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB]
  connect_bd_intf_net -intf_net microblaze_1_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_1_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_1_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_1_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]

  # Create port connections
  connect_bd_net -net microblaze_1_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk]
  connect_bd_net -net proc_sys_reset_1_bus_struct_reset [get_bd_pins LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst]
  
  # Restore current instance
  current_bd_instance $oldCurInst
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

# Add the Memory controller (MIG) for the DDR3
set mig_7series_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:2.4  mig_7series_1 ]
set folder [pwd]
set mig_file [glob $folder/src/mig/mig_kc705*.prj]
if { [file exists "$mig_file"] == 1 } { 
   set str_mig_folder [get_property IP_DIR [ get_ips [ get_property CONFIG.Component_Name $mig_7series_1 ] ] ]
   puts "Copying <$mig_file> to <$str_mig_folder/mig_a.prj>..."
   file copy $mig_file "$str_mig_folder/mig_a.prj"
}
set_property -dict [ list CONFIG.XML_INPUT_FILE {mig_a.prj} CONFIG.RESET_BOARD_INTERFACE {Custom}  ] $mig_7series_1

# Connect MIG external interfaces
startgroup
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 ddr3_sdram
connect_bd_intf_net [get_bd_intf_pins mig_7series_1/DDR3] [get_bd_intf_ports ddr3_sdram]
endgroup
startgroup
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_diff_clock
connect_bd_intf_net [get_bd_intf_pins mig_7series_1/SYS_CLK] [get_bd_intf_ports sys_diff_clock]
endgroup

# Create ports
set perst_n [ create_bd_port -dir I -type rst perst_n ]
set_property -dict [ list CONFIG.POLARITY {ACTIVE_LOW}  ] $perst_n
set mmcm_lock [ create_bd_port -dir O mmcm_lock ]
set init_calib_complete [ create_bd_port -dir O init_calib_complete ]
set reset [ create_bd_port -dir I -type rst reset ]
set_property -dict [ list CONFIG.POLARITY {ACTIVE_HIGH}  ] $reset

# Create instance: axi_pcie_1, and set properties
set axi_pcie_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie:2.7 axi_pcie_1 ]
set_property -dict [list CONFIG.INCLUDE_RC {Root_Port_of_PCI_Express_Root_Complex} CONFIG.NO_OF_LANES {X4} CONFIG.MAX_LINK_SPEED {5.0_GT/s} CONFIG.BAR0_SCALE {Gigabytes} CONFIG.DEVICE_ID {0x7014} CONFIG.BASE_CLASS_MENU {Bridge_device} CONFIG.SUB_CLASS_INTERFACE_MENU {InfiniBand_to_PCI_host_bridge} CONFIG.BAR0_SIZE {1} CONFIG.S_AXI_DATA_WIDTH {128} CONFIG.M_AXI_DATA_WIDTH {128} CONFIG.XLNX_REF_BOARD {KC705_REVC}] $axi_pcie_1
# Create instance: axi_interconnect_1, and set properties
set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1 ]
set_property -dict [ list CONFIG.NUM_SI {3} CONFIG.NUM_MI {5}  ] $axi_interconnect_1

# Create instance: axi_bram_ctrl_1, and set properties
set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_1 ]

# Create instance: blk_mem_gen_1, and set properties
set blk_mem_gen_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 blk_mem_gen_1 ]
set_property -dict [ list CONFIG.Memory_Type {True_Dual_Port_RAM}  ] $blk_mem_gen_1

# Create instance: axi_cdma_1, and set properties
set axi_cdma_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_1 ]
set_property -dict [ list CONFIG.C_M_AXI_DATA_WIDTH {128} CONFIG.C_INCLUDE_SG {0}  ] $axi_cdma_1

# Create instance: microblaze_1, and set properties
set microblaze_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.5 microblaze_1 ]
set_property -dict [ list CONFIG.C_FAULT_TOLERANT {0} CONFIG.C_D_AXI {1} CONFIG.C_D_LMB {1} CONFIG.C_I_LMB {1} CONFIG.C_DEBUG_ENABLED {1} CONFIG.C_USE_INTERRUPT {0}  ] $microblaze_1

# Create instance: microblaze_1_local_memory
create_hier_cell_microblaze_1_local_memory [current_bd_instance .] microblaze_1_local_memory

# Create instance: mdm_1, and set properties
set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]

# Create instance: proc_sys_reset_1, and set properties
set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1 ]

# Create interface connections
connect_bd_intf_net -intf_net axi_interconnect_1_m00_axi [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins axi_pcie_1/S_AXI]
connect_bd_intf_net -intf_net axi_interconnect_1_m01_axi [get_bd_intf_pins axi_interconnect_1/M01_AXI] [get_bd_intf_pins axi_pcie_1/S_AXI_CTL]
connect_bd_intf_net -intf_net axi_pcie_1_m_axi [get_bd_intf_pins axi_pcie_1/M_AXI] [get_bd_intf_pins axi_interconnect_1/S00_AXI]
set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {true}  ] [get_bd_intf_nets axi_pcie_1_m_axi]
connect_bd_intf_net -intf_net axi_interconnect_1_m02_axi [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] [get_bd_intf_pins axi_interconnect_1/M02_AXI]
set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {true}  ] [get_bd_intf_nets axi_interconnect_1_m02_axi]
connect_bd_intf_net -intf_net axi_bram_ctrl_1_bram_porta [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA]
connect_bd_intf_net -intf_net axi_bram_ctrl_1_bram_portb [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTB]
connect_bd_intf_net -intf_net axi_cdma_1_m_axi [get_bd_intf_pins axi_cdma_1/m_axi] [get_bd_intf_pins axi_interconnect_1/S01_AXI]
connect_bd_intf_net -intf_net axi_interconnect_1_m03_axi [get_bd_intf_pins axi_cdma_1/s_axi_lite] [get_bd_intf_pins axi_interconnect_1/M03_AXI]
connect_bd_intf_net -intf_net axi_interconnect_1_m04_axi [get_bd_intf_pins mig_7series_1/S_AXI] [get_bd_intf_pins axi_interconnect_1/M04_AXI]
set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {true}  ] [get_bd_intf_nets axi_interconnect_1_m04_axi]
connect_bd_intf_net -intf_net microblaze_1_dlmb [get_bd_intf_pins microblaze_1/DLMB] [get_bd_intf_pins microblaze_1_local_memory/DLMB]
connect_bd_intf_net -intf_net microblaze_1_ilmb [get_bd_intf_pins microblaze_1/ILMB] [get_bd_intf_pins microblaze_1_local_memory/ILMB]
connect_bd_intf_net -intf_net microblaze_1_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_1/DEBUG]
connect_bd_intf_net -intf_net microblaze_1_m_axi_dp [get_bd_intf_pins microblaze_1/M_AXI_DP] [get_bd_intf_pins axi_interconnect_1/S02_AXI]

# Create port connections
connect_bd_net -net axi_aresetn_1 [get_bd_ports perst_n] [get_bd_pins axi_pcie_1/axi_aresetn]
connect_bd_net -net axi_pcie_1_axi_aclk_out [get_bd_pins axi_pcie_1/axi_aclk_out] [get_bd_pins axi_pcie_1/axi_aclk] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK]
connect_bd_net -net axi_pcie_1_axi_ctl_aclk_out [get_bd_pins axi_pcie_1/axi_ctl_aclk_out] [get_bd_pins axi_pcie_1/axi_ctl_aclk] [get_bd_pins axi_interconnect_1/M01_ACLK]
connect_bd_net -net axi_pcie_1_mmcm_lock [get_bd_ports mmcm_lock] [get_bd_pins axi_pcie_1/mmcm_lock]
set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {true}  ] [get_bd_nets axi_pcie_1_mmcm_lock]
connect_bd_net -net mig_7series_1_mmcm_locked [get_bd_pins mig_7series_1/mmcm_locked] [get_bd_pins axi_bram_ctrl_1/S_AXI_ARESETN] [get_bd_pins axi_interconnect_1/M04_ARESETN] [get_bd_pins axi_interconnect_1/M03_ARESETN] [get_bd_pins axi_interconnect_1/S01_ARESETN] [get_bd_pins axi_interconnect_1/M02_ARESETN] [get_bd_pins axi_interconnect_1/M01_ARESETN] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_cdma_1/s_axi_lite_aresetn] [get_bd_pins proc_sys_reset_1/dcm_locked]
set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {true}  ] [get_bd_nets mig_7series_1_mmcm_locked]
connect_bd_net -net mig_7series_1_init_calib_complete [get_bd_ports init_calib_complete] [get_bd_pins mig_7series_1/init_calib_complete]
set_property -dict [ list HDL_ATTRIBUTE.MARK_DEBUG {true}  ] [get_bd_nets mig_7series_1_init_calib_complete]
connect_bd_net -net microblaze_1_Clk [get_bd_pins mig_7series_1/ui_addn_clk_0] [get_bd_pins axi_bram_ctrl_1/S_AXI_ACLK] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M02_ACLK] [get_bd_pins axi_interconnect_1/S01_ACLK] [get_bd_pins axi_interconnect_1/M03_ACLK] [get_bd_pins axi_cdma_1/m_axi_aclk] [get_bd_pins axi_cdma_1/s_axi_lite_aclk] [get_bd_pins microblaze_1/Clk] [get_bd_pins proc_sys_reset_1/slowest_sync_clk] [get_bd_pins microblaze_1_local_memory/LMB_Clk] [get_bd_pins axi_interconnect_1/S02_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins axi_interconnect_1/M04_ACLK]
connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins mig_7series_1/sys_rst] [get_bd_pins proc_sys_reset_1/ext_reset_in]
connect_bd_net -net proc_sys_reset_1_bus_struct_reset [get_bd_pins proc_sys_reset_1/bus_struct_reset] [get_bd_pins microblaze_1_local_memory/LMB_Rst]
connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins proc_sys_reset_1/mb_debug_sys_rst]
connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_1/S02_ARESETN]
connect_bd_net -net proc_sys_reset_1_mb_reset [get_bd_pins proc_sys_reset_1/mb_reset] [get_bd_pins microblaze_1/Reset]

# Add MGT external port for PCIe
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_exp
connect_bd_intf_net [get_bd_intf_pins axi_pcie_1/pcie_7x_mgt] [get_bd_intf_ports pci_exp]

# Add constant to tie off /axi_pcie_1/INTX_MSI_Request
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells xlconstant_0]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins axi_pcie_1/INTX_MSI_Request]
endgroup

# Add differential buffer for the 100MHz PCIe reference clock
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 ref_clk_buf
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] [get_bd_cells ref_clk_buf]
connect_bd_net [get_bd_pins ref_clk_buf/IBUF_OUT] [get_bd_pins axi_pcie_1/REFCLK]
endgroup
startgroup
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk
connect_bd_intf_net [get_bd_intf_pins ref_clk_buf/CLK_IN_D] [get_bd_intf_ports ref_clk]
endgroup

# Add Processor System Reset to synchronize PERST_N for MIG
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins mig_7series_1/ui_clk]
connect_bd_net [get_bd_ports perst_n] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins proc_sys_reset_0/dcm_locked] [get_bd_pins mig_7series_1/mmcm_locked]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins mig_7series_1/aresetn]
endgroup

# Add UART for console output
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_0
endgroup
startgroup
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_1 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_uart16550_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "rs232_uart ( UART ) " }  [get_bd_intf_pins axi_uart16550_0/UART]
endgroup

# Create address segments
create_bd_addr_seg -range 0x10000 -offset 0x76000000 [get_bd_addr_spaces axi_pcie_1/M_AXI] [get_bd_addr_segs axi_pcie_1/S_AXI_CTL/CTL0] SEG1
create_bd_addr_seg -range 0x10000 -offset 0x76010000 [get_bd_addr_spaces axi_pcie_1/M_AXI] [get_bd_addr_segs axi_pcie_1/S_AXI/BAR0] SEG2
create_bd_addr_seg -range 0x8000 -offset 0xC0000000 [get_bd_addr_spaces axi_pcie_1/M_AXI] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] SEG3
create_bd_addr_seg -range 0x10000 -offset 0xD0000000 [get_bd_addr_spaces axi_pcie_1/M_AXI] [get_bd_addr_segs axi_cdma_1/s_axi_lite/Reg] SEG4
create_bd_addr_seg -range 0x40000000 -offset 0x80000000 [get_bd_addr_spaces axi_pcie_1/M_AXI] [get_bd_addr_segs mig_7series_1/memmap/memaddr] SEG5
create_bd_addr_seg -range 0x10000 -offset 0x76000000 [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs axi_pcie_1/S_AXI_CTL/CTL0] SEG1
create_bd_addr_seg -range 0x10000 -offset 0x76010000 [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs axi_pcie_1/S_AXI/BAR0] SEG2
create_bd_addr_seg -range 0x8000 -offset 0xC0000000 [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] SEG3
create_bd_addr_seg -range 0x10000 -offset 0xD0000000 [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs axi_cdma_1/s_axi_lite/Reg] SEG5
create_bd_addr_seg -range 0x40000000 -offset 0x80000000 [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs mig_7series_1/memmap/memaddr] SEG6
create_bd_addr_seg -range 128K -offset 0x0 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs microblaze_1_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] SEG2
create_bd_addr_seg -range 128K -offset 0x0 [get_bd_addr_spaces microblaze_1/Instruction] [get_bd_addr_segs microblaze_1_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] SEG1
assign_bd_address

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design
