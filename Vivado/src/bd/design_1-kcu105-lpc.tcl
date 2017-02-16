################################################################
# Block design build script for KCU105
################################################################

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
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 dlmb_v10 ]

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 ilmb_v10 ]

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr dlmb_bram_if_cntlr ]
  set_property -dict [ list CONFIG.C_ECC {0}  ] $dlmb_bram_if_cntlr

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr ilmb_bram_if_cntlr ]
  set_property -dict [ list CONFIG.C_ECC {0}  ] $ilmb_bram_if_cntlr

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen lmb_bram ]
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
create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 ddr4_0

# Connect MIG external interfaces
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "default_sysclk_300 ( 300 MHz System differential clock ) " }  [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "ddr4_sdram ( DDR4 SDRAM ) " }  [get_bd_intf_pins ddr4_0/C0_DDR4]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "reset ( FPGA Reset ) " }  [get_bd_pins ddr4_0/sys_rst]

# Create ports
#set mmcm_lock [ create_bd_port -dir O mmcm_lock ]
set init_calib_complete [ create_bd_port -dir O init_calib_complete ]

# Create AXI Memory Mapped to PCIe Bridge IP and set properties
set axi_pcie_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3 axi_pcie_1 ]
set_property -dict [list CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
CONFIG.pcie_blk_locn {X0Y1} \
CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
CONFIG.pf0_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
CONFIG.pf0_class_code_sub {04} \
CONFIG.pf0_bar0_scale {Gigabytes} \
CONFIG.pf0_bar0_64bit {true} \
CONFIG.axibar2pciebar_0 {0x0000000040000000} \
CONFIG.plltype {QPLL1} \
CONFIG.axisten_freq {125} \
CONFIG.dedicate_perst {false} \
CONFIG.pf0_device_id {8131} \
CONFIG.pf0_base_class_menu {Bridge_device} \
CONFIG.pf0_class_code_base {06} \
CONFIG.pf0_class_code {060400} \
CONFIG.pf0_msix_cap_table_bir {BAR_1:0} \
CONFIG.pf0_msix_cap_pba_bir {BAR_1:0}] $axi_pcie_1
# Add MGT external port for PCIe
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_exp
connect_bd_intf_net [get_bd_intf_pins axi_pcie_1/pcie_7x_mgt] [get_bd_intf_ports pci_exp]
# Add constant to tie off /axi_pcie_1/intx_msi_Request
set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]
set_property -dict [list CONFIG.CONST_VAL {0}] $xlconstant_0
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins axi_pcie_1/intx_msi_Request]
# Add differential buffer for the 100MHz PCIe reference clock
set ref_clk_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf ref_clk_buf ]
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] $ref_clk_buf
# refclk and sys_clk_gt connected as per page 10 of AXI Bridge PCIe Gen3 Product guide
# http://www.xilinx.com/support/documentation/ip_documentation/axi_pcie3/v2_0/pg194-axi-bridge-pcie-gen3.pdf
connect_bd_net [get_bd_pins ref_clk_buf/IBUF_DS_ODIV2] [get_bd_pins axi_pcie_1/refclk]
connect_bd_net [get_bd_pins ref_clk_buf/IBUF_OUT] [get_bd_pins axi_pcie_1/sys_clk_gt]
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk
connect_bd_intf_net [get_bd_intf_pins ref_clk_buf/CLK_IN_D] [get_bd_intf_ports ref_clk]

# Create AXI interconnects and set properties

# Create mem_intercon
set mem_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect mem_intercon ]
set_property -dict [ list CONFIG.NUM_SI {4} CONFIG.NUM_MI {1}  ] $mem_intercon
# Create cdma_intercon
set cdma_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect cdma_intercon ]
set_property -dict [ list CONFIG.NUM_SI {1} CONFIG.NUM_MI {2}  ] $cdma_intercon
# Create periph_intercon
set periph_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect periph_intercon ]
set_property -dict [ list CONFIG.NUM_SI {1} CONFIG.NUM_MI {5}  ] $periph_intercon
# Create pcie_intercon
set pcie_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect pcie_intercon ]
set_property -dict [ list CONFIG.NUM_SI {2} CONFIG.NUM_MI {2}  ] $pcie_intercon

# Create Microblaze and set properties
set microblaze_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_1 ]
set_property -dict [list CONFIG.G_TEMPLATE_LIST {4} CONFIG.G_USE_EXCEPTIONS {1} CONFIG.C_USE_MSR_INSTR {1} CONFIG.C_USE_PCMP_INSTR {1} CONFIG.C_USE_BARREL {1} CONFIG.C_USE_DIV {1} CONFIG.C_USE_HW_MUL {2} CONFIG.C_UNALIGNED_EXCEPTIONS {1} CONFIG.C_ILL_OPCODE_EXCEPTION {1} CONFIG.C_M_AXI_I_BUS_EXCEPTION {1} CONFIG.C_M_AXI_D_BUS_EXCEPTION {1} CONFIG.C_DIV_ZERO_EXCEPTION {1} CONFIG.C_PVR {2} CONFIG.C_OPCODE_0x0_ILLEGAL {1} CONFIG.C_USE_ICACHE {1} CONFIG.C_CACHE_BYTE_SIZE {16384} CONFIG.C_ICACHE_LINE_LEN {8} CONFIG.C_ICACHE_VICTIMS {8} CONFIG.C_ICACHE_STREAMS {1} CONFIG.C_USE_DCACHE {1} CONFIG.C_DCACHE_BYTE_SIZE {16384} CONFIG.C_DCACHE_VICTIMS {8} CONFIG.C_USE_MMU {3} CONFIG.C_MMU_ZONES {2} CONFIG.C_USE_INTERRUPT {1}] $microblaze_1
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins microblaze_1/Clk]

# Create microblaze_1_local_memory
create_hier_cell_microblaze_1_local_memory [current_bd_instance .] microblaze_1_local_memory
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins microblaze_1_local_memory/LMB_Clk]

# Create instance: mdm_1, and set properties
set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm mdm_1 ]

# Create rst_ddr4_0_300M for the MIG addn_ui_clkout1
set rst_ddr4_0_300M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_ddr4_0_300M ]

# Create proc_sys_reset_0 for the CTRL clock generated by PCIe block
set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]
create_bd_port -dir O -from 0 -to 0 -type rst perst
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_reset] [get_bd_ports perst]
connect_bd_net [get_bd_pins axi_pcie_1/axi_ctl_aresetn] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins axi_pcie_1/axi_aclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]

# Create rst_ddr4_0_100M for the MIG c0_ddr4_ui_clk
set rst_ddr4_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_ddr4_0_100M ]

# Add AXI interrupt controller
set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]
set_property -dict [list CONFIG.C_HAS_FAST {1}] $axi_intc_0
connect_bd_intf_net [get_bd_intf_pins axi_intc_0/interrupt] [get_bd_intf_pins microblaze_1/INTERRUPT]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins axi_intc_0/s_axi_aclk]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins axi_intc_0/processor_clk]

# Add concat for interrupts
set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]
set_property -dict [list CONFIG.NUM_PORTS {4}] $xlconcat_0
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins axi_intc_0/intr]
connect_bd_net -net axi_pcie_1_interrupt_out [get_bd_pins axi_pcie_1/interrupt_out] [get_bd_pins xlconcat_0/In3]

# Create AXI CDMA and set properties
set axi_cdma_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma axi_cdma_1 ]
set_property -dict [ list CONFIG.C_M_AXI_DATA_WIDTH {128} CONFIG.C_INCLUDE_SG {0}  ] $axi_cdma_1
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins axi_cdma_1/m_axi_aclk]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins axi_cdma_1/s_axi_lite_aclk]
connect_bd_net -net axi_cdma_1_cdma_introut [get_bd_pins axi_cdma_1/cdma_introut] [get_bd_pins xlconcat_0/In2]

# Add UART for console output
set axi_uart16550_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550 axi_uart16550_0 ]
set_property -dict [list CONFIG.UART_BOARD_INTERFACE {rs232_uart} CONFIG.UART_BOARD_INTERFACE {rs232_uart}] $axi_uart16550_0
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart
connect_bd_intf_net [get_bd_intf_pins axi_uart16550_0/UART] [get_bd_intf_ports rs232_uart]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins axi_uart16550_0/s_axi_aclk]
connect_bd_net [get_bd_pins axi_uart16550_0/ip2intc_irpt] [get_bd_pins xlconcat_0/In0]

# Add AXI Timer
set axi_timer_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer axi_timer_0 ]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins axi_timer_0/s_axi_aclk]
connect_bd_net [get_bd_pins axi_timer_0/interrupt] [get_bd_pins xlconcat_0/In1]

# mem_intercon interface connections
connect_bd_intf_net -intf_net mem_intercon_m00_axi [get_bd_intf_pins mem_intercon/M00_AXI] [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
connect_bd_intf_net -intf_net microblaze_1_m_axi_dc [get_bd_intf_pins microblaze_1/M_AXI_DC] [get_bd_intf_pins mem_intercon/S00_AXI]
connect_bd_intf_net -intf_net microblaze_1_m_axi_ic [get_bd_intf_pins microblaze_1/M_AXI_IC] [get_bd_intf_pins mem_intercon/S01_AXI]
connect_bd_intf_net -intf_net cdma_intercon_m01_axi [get_bd_intf_pins cdma_intercon/M01_AXI] [get_bd_intf_pins mem_intercon/S02_AXI]
connect_bd_intf_net -intf_net axi_pcie_1_m_axi [get_bd_intf_pins axi_pcie_1/M_AXI] [get_bd_intf_pins mem_intercon/S03_AXI]

# mem_intercon clocks
connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins ddr4_0/c0_ddr4_ui_clk] [get_bd_pins mem_intercon/M00_ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins mem_intercon/ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins mem_intercon/S00_ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins mem_intercon/S01_ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins mem_intercon/S02_ACLK]
connect_bd_net -net axi_pcie_1_axi_aclk [get_bd_pins axi_pcie_1/axi_aclk] [get_bd_pins mem_intercon/S03_ACLK]

# cdma_intercon interface connections
connect_bd_intf_net -intf_net cdma_intercon_m00_axi [get_bd_intf_pins cdma_intercon/M00_AXI] [get_bd_intf_pins pcie_intercon/S00_AXI]
connect_bd_intf_net -intf_net axi_cdma_1_m_axi [get_bd_intf_pins axi_cdma_1/M_AXI] [get_bd_intf_pins cdma_intercon/S00_AXI]

# cdma_intercon clocks
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins cdma_intercon/ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins cdma_intercon/S00_ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins cdma_intercon/M00_ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins cdma_intercon/M01_ACLK]

# periph_intercon interface connections
connect_bd_intf_net -intf_net periph_intercon_m00_axi [get_bd_intf_pins periph_intercon/M00_AXI] [get_bd_intf_pins axi_cdma_1/S_AXI_LITE]
connect_bd_intf_net -intf_net periph_intercon_m01_axi [get_bd_intf_pins periph_intercon/M01_AXI] [get_bd_intf_pins axi_uart16550_0/S_AXI]
connect_bd_intf_net -intf_net periph_intercon_m02_axi [get_bd_intf_pins periph_intercon/M02_AXI] [get_bd_intf_pins axi_timer_0/S_AXI]
connect_bd_intf_net -intf_net periph_intercon_m03_axi [get_bd_intf_pins periph_intercon/M03_AXI] [get_bd_intf_pins axi_intc_0/s_axi]
connect_bd_intf_net -intf_net periph_intercon_m04_axi [get_bd_intf_pins periph_intercon/M04_AXI] [get_bd_intf_pins pcie_intercon/S01_AXI]
connect_bd_intf_net -intf_net microblaze_1_m_axi_dp [get_bd_intf_pins microblaze_1/M_AXI_DP] [get_bd_intf_pins periph_intercon/S00_AXI]

# periph_intercon clocks
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins periph_intercon/ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins periph_intercon/S00_ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins periph_intercon/M00_ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins periph_intercon/M01_ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins periph_intercon/M02_ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins periph_intercon/M03_ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins periph_intercon/M04_ACLK]

# pcie_intercon interface connections - S00_AXI and S01_AXI connections made previously
connect_bd_intf_net -intf_net pcie_intercon_m00_axi [get_bd_intf_pins pcie_intercon/M00_AXI] [get_bd_intf_pins axi_pcie_1/S_AXI]
connect_bd_intf_net -intf_net pcie_intercon_m01_axi [get_bd_intf_pins pcie_intercon/M01_AXI] [get_bd_intf_pins axi_pcie_1/S_AXI_CTL]

# pcie_intercon clocks
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins pcie_intercon/ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins pcie_intercon/S00_ACLK]
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins pcie_intercon/S01_ACLK]
connect_bd_net -net axi_pcie_1_axi_aclk [get_bd_pins axi_pcie_1/axi_aclk] [get_bd_pins pcie_intercon/M00_ACLK]
connect_bd_net -net axi_pcie_1_axi_aclk [get_bd_pins axi_pcie_1/axi_aclk] [get_bd_pins pcie_intercon/M01_ACLK]

# Microblaze interface connections
connect_bd_intf_net -intf_net microblaze_1_dlmb [get_bd_intf_pins microblaze_1/DLMB] [get_bd_intf_pins microblaze_1_local_memory/DLMB]
connect_bd_intf_net -intf_net microblaze_1_ilmb [get_bd_intf_pins microblaze_1/ILMB] [get_bd_intf_pins microblaze_1_local_memory/ILMB]
connect_bd_intf_net -intf_net microblaze_1_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_1/DEBUG]

# rst_ddr4_0_300M connections
connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins ddr4_0/c0_ddr4_ui_clk] [get_bd_pins rst_ddr4_0_300M/slowest_sync_clk]
connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] [get_bd_pins rst_ddr4_0_300M/ext_reset_in]
connect_bd_net -net rst_ddr4_0_300M_peripheral_aresetn [get_bd_pins rst_ddr4_0_300M/peripheral_aresetn] [get_bd_pins mem_intercon/M00_ARESETN]
connect_bd_net -net rst_ddr4_0_300M_peripheral_aresetn [get_bd_pins rst_ddr4_0_300M/peripheral_aresetn] [get_bd_pins ddr4_0/c0_ddr4_aresetn]

# rst_ddr4_0_100M connections
connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins rst_ddr4_0_100M/slowest_sync_clk]
connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins rst_ddr4_0_100M/ext_reset_in]
connect_bd_net -net rst_ddr4_0_100M_mb_reset [get_bd_pins rst_ddr4_0_100M/mb_reset] [get_bd_pins microblaze_1/Reset]
connect_bd_net -net rst_ddr4_0_100M_mb_reset [get_bd_pins rst_ddr4_0_100M/mb_reset] [get_bd_pins axi_intc_0/processor_rst]
connect_bd_net -net mdm_1_Debug_SYS_Rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_ddr4_0_100M/mb_debug_sys_rst]
connect_bd_net -net rst_ddr4_0_100M_bus_struct_reset [get_bd_pins rst_ddr4_0_100M/bus_struct_reset] [get_bd_pins microblaze_1_local_memory/LMB_Rst]
connect_bd_net -net rst_ddr4_0_100M_interconnect_aresetn [get_bd_pins rst_ddr4_0_100M/interconnect_aresetn] [get_bd_pins cdma_intercon/ARESETN]
connect_bd_net -net rst_ddr4_0_100M_interconnect_aresetn [get_bd_pins rst_ddr4_0_100M/interconnect_aresetn] [get_bd_pins periph_intercon/ARESETN]
connect_bd_net -net rst_ddr4_0_100M_interconnect_aresetn [get_bd_pins rst_ddr4_0_100M/interconnect_aresetn] [get_bd_pins pcie_intercon/ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins mem_intercon/S00_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins mem_intercon/S01_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins mem_intercon/S02_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins cdma_intercon/S00_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins cdma_intercon/M00_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins cdma_intercon/M01_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins periph_intercon/S00_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins periph_intercon/M00_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins periph_intercon/M01_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins periph_intercon/M02_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins periph_intercon/M03_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins periph_intercon/M04_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins pcie_intercon/S00_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins pcie_intercon/S01_ARESETN]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins axi_cdma_1/s_axi_lite_aresetn]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins axi_uart16550_0/s_axi_aresetn]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins axi_timer_0/s_axi_aresetn]
connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins axi_intc_0/s_axi_aresetn]
connect_bd_net -net rst_ddr4_0_100M_interconnect_aresetn [get_bd_pins rst_ddr4_0_100M/interconnect_aresetn] [get_bd_pins mem_intercon/ARESETN]

# PCIe AXI reset signal
connect_bd_net -net axi_pcie_1_axi_aresetn [get_bd_pins axi_pcie_1/axi_aresetn] [get_bd_pins mem_intercon/S03_ARESETN]
connect_bd_net -net axi_pcie_1_axi_aresetn [get_bd_pins axi_pcie_1/axi_aresetn] [get_bd_pins pcie_intercon/M00_ARESETN]
connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins pcie_intercon/M01_ARESETN]

# Inverter for the external reset input signal
set util_vector_logic_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0]
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] $util_vector_logic_0
connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins util_vector_logic_0/Op1]
# Reset for PCIe
connect_bd_net -net util_vector_logic_0_Res [get_bd_pins util_vector_logic_0/Res] [get_bd_pins axi_pcie_1/sys_rst_n]

# Create external port connections
#connect_bd_net -net ddr4_0_mmcm_locked [get_bd_ports mmcm_lock] [get_bd_pins ddr4_0/mmcm_locked]
connect_bd_net -net ddr4_0_init_calib_complete [get_bd_ports init_calib_complete] [get_bd_pins ddr4_0/c0_init_calib_complete]

# AXI PCIe address segments
create_bd_addr_seg -range 1G -offset 0x80000000 [get_bd_addr_spaces axi_pcie_1/M_AXI] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] DDR_SEG

# CDMA address segments
create_bd_addr_seg -range 64M -offset 0x50000000 [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs axi_pcie_1/S_AXI_CTL/CTL0] PCI_CTL_SEG
create_bd_addr_seg -range 256M -offset 0x60000000 [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs axi_pcie_1/S_AXI/BAR0] PCI_BAR0_SEG
create_bd_addr_seg -range 1G -offset 0x80000000 [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] DDR_SEG

# Microblaze address segments
create_bd_addr_seg -range 128K -offset 0x0 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs microblaze_1_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] LOCAL_MEM_SEG
create_bd_addr_seg -range 64M -offset 0x50000000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_pcie_1/S_AXI_CTL/CTL0] PCI_CTL_SEG
create_bd_addr_seg -range 256M -offset 0x60000000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_pcie_1/S_AXI/BAR0] PCI_BAR0_SEG
create_bd_addr_seg -range 1G -offset 0x80000000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] DDR_SEG
create_bd_addr_seg -range 64K -offset 0x44A00000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_cdma_1/S_AXI_LITE/Reg] CDMA_SEG
create_bd_addr_seg -range 64K -offset 0x44A10000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_uart16550_0/S_AXI/Reg] UART_SEG
create_bd_addr_seg -range 64K -offset 0x41C00000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_timer_0/S_AXI/Reg] TIMER_SEG
create_bd_addr_seg -range 64K -offset 0x41200000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_intc_0/S_AXI/Reg] INTC_SEG
create_bd_addr_seg -range 128K -offset 0x0 [get_bd_addr_spaces microblaze_1/Instruction] [get_bd_addr_segs microblaze_1_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] LOCAL_MEM_SEG
create_bd_addr_seg -range 1G -offset 0x80000000 [get_bd_addr_spaces microblaze_1/Instruction] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] DDR_SEG

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design
