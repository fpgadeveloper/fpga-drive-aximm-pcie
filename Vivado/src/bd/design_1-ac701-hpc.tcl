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
set mig_file [glob $folder/src/mig/mig_ac701*.prj]
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

# Create AXI Memory Mapped to PCIe Bridge IP and set properties
set axi_pcie_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie:2.7 axi_pcie_1 ]
set_property -dict [list CONFIG.INCLUDE_RC {Root_Port_of_PCI_Express_Root_Complex} CONFIG.NO_OF_LANES {X2} CONFIG.MAX_LINK_SPEED {2.5_GT/s} CONFIG.BAR0_SCALE {Gigabytes} CONFIG.DEVICE_ID {0x7014} CONFIG.BASE_CLASS_MENU {Bridge_device} CONFIG.SUB_CLASS_INTERFACE_MENU {InfiniBand_to_PCI_host_bridge} CONFIG.BAR0_SIZE {1} CONFIG.S_AXI_DATA_WIDTH {128} CONFIG.M_AXI_DATA_WIDTH {128} CONFIG.XLNX_REF_BOARD {AC701}] $axi_pcie_1
# Class code required to use the right driver
set_property -dict [list CONFIG.CLASS_CODE {0x060400}] $axi_pcie_1
# Hide RP BAR0 to enable end-point to access entire 32-bit address range.
#  Not sure why, but hiding RP BAR0 seems necessary for the Microblaze design, or we get kernel crashes.
#  Strangely, we don't need to hide the RP BAR0 on the Zynq design.
#  Here are some of the errors in the bootlog when RP BAR0 was not hidden:
#    nvme 0000:01:00.0: Failed status: 3, reset controller
#    nvme 0000:01:00.0: Cancelling I/O 0 QID 0
#    nvme 0000:01:00.0: Could not set queue count (7)
set_property -dict [list CONFIG.BAR_64BIT {true} CONFIG.BAR0_SCALE {Gigabytes} CONFIG.BAR0_SIZE {4} CONFIG.PCIEBAR2AXIBAR_0 {0x00} CONFIG.rp_bar_hide {true}] $axi_pcie_1
# Add MGT external port for PCIe
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_exp
connect_bd_intf_net [get_bd_intf_pins axi_pcie_1/pcie_7x_mgt] [get_bd_intf_ports pci_exp]
# Add constant to tie off /axi_pcie_1/INTX_MSI_Request
set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
set_property -dict [list CONFIG.CONST_VAL {0}] $xlconstant_0
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins axi_pcie_1/INTX_MSI_Request]
# Add differential buffer for the 100MHz PCIe reference clock
set ref_clk_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 ref_clk_buf ]
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] $ref_clk_buf
connect_bd_net [get_bd_pins ref_clk_buf/IBUF_OUT] [get_bd_pins axi_pcie_1/REFCLK]
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk
connect_bd_intf_net [get_bd_intf_pins ref_clk_buf/CLK_IN_D] [get_bd_intf_ports ref_clk]

# Create AXI interconnects and set properties

# Create mem_intercon
set mem_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 mem_intercon ]
set_property -dict [ list CONFIG.NUM_SI {4} CONFIG.NUM_MI {1}  ] $mem_intercon
# Create cdma_intercon
set cdma_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 cdma_intercon ]
set_property -dict [ list CONFIG.NUM_SI {1} CONFIG.NUM_MI {2}  ] $cdma_intercon
# Create periph_intercon
set periph_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 periph_intercon ]
set_property -dict [ list CONFIG.NUM_SI {1} CONFIG.NUM_MI {6}  ] $periph_intercon
# Create pcie_intercon
set pcie_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 pcie_intercon ]
set_property -dict [ list CONFIG.NUM_SI {2} CONFIG.NUM_MI {2}  ] $pcie_intercon

# Create Microblaze and set properties
set microblaze_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.5 microblaze_1 ]
set_property -dict [list CONFIG.G_TEMPLATE_LIST {4} CONFIG.G_USE_EXCEPTIONS {1} CONFIG.C_USE_MSR_INSTR {1} CONFIG.C_USE_PCMP_INSTR {1} CONFIG.C_USE_BARREL {1} CONFIG.C_USE_DIV {1} CONFIG.C_USE_HW_MUL {2} CONFIG.C_UNALIGNED_EXCEPTIONS {1} CONFIG.C_ILL_OPCODE_EXCEPTION {1} CONFIG.C_M_AXI_I_BUS_EXCEPTION {1} CONFIG.C_M_AXI_D_BUS_EXCEPTION {1} CONFIG.C_DIV_ZERO_EXCEPTION {1} CONFIG.C_PVR {2} CONFIG.C_OPCODE_0x0_ILLEGAL {1} CONFIG.C_USE_ICACHE {1} CONFIG.C_CACHE_BYTE_SIZE {16384} CONFIG.C_ICACHE_LINE_LEN {8} CONFIG.C_ICACHE_VICTIMS {8} CONFIG.C_ICACHE_STREAMS {1} CONFIG.C_USE_DCACHE {1} CONFIG.C_DCACHE_BYTE_SIZE {16384} CONFIG.C_DCACHE_VICTIMS {8} CONFIG.C_USE_MMU {3} CONFIG.C_MMU_ZONES {2} CONFIG.C_USE_INTERRUPT {1}] $microblaze_1
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins microblaze_1/Clk]

# Create microblaze_1_local_memory
create_hier_cell_microblaze_1_local_memory [current_bd_instance .] microblaze_1_local_memory
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins microblaze_1_local_memory/LMB_Clk]

# Create instance: mdm_1, and set properties
set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]

# Create proc_sys_reset_0 for the main clock generated by PCIe block
set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

# Create proc_sys_reset_1 for the CTRL clock generated by PCIe block
set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1 ]

# Create proc_sys_reset_2 for the MIG ui_clk
set proc_sys_reset_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_2 ]

# Add AXI interrupt controller
set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 axi_intc_0 ]
set_property -dict [list CONFIG.C_HAS_FAST {1}] $axi_intc_0
connect_bd_intf_net [get_bd_intf_pins axi_intc_0/interrupt] [get_bd_intf_pins microblaze_1/INTERRUPT]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins axi_intc_0/s_axi_aclk]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins axi_intc_0/processor_clk]

# Add concat for interrupts
set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
set_property -dict [list CONFIG.NUM_PORTS {5}] $xlconcat_0
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins axi_intc_0/intr]
connect_bd_net -net axi_pcie_1_interrupt_out [get_bd_pins axi_pcie_1/interrupt_out] [get_bd_pins xlconcat_0/In4]

# Create AXI CDMA and set properties
set axi_cdma_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_1 ]
set_property -dict [ list CONFIG.C_M_AXI_DATA_WIDTH {128} CONFIG.C_INCLUDE_SG {0}  ] $axi_cdma_1
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins axi_cdma_1/m_axi_aclk]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins axi_cdma_1/s_axi_lite_aclk]
connect_bd_net -net axi_cdma_1_cdma_introut [get_bd_pins axi_cdma_1/cdma_introut] [get_bd_pins xlconcat_0/In3]

# Add UART for console output
set axi_uart16550_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_0 ]
set_property -dict [list CONFIG.UART_BOARD_INTERFACE {rs232_uart} CONFIG.UART_BOARD_INTERFACE {rs232_uart}] $axi_uart16550_0
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart
connect_bd_intf_net [get_bd_intf_pins axi_uart16550_0/UART] [get_bd_intf_ports rs232_uart]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins axi_uart16550_0/s_axi_aclk]
connect_bd_net [get_bd_pins axi_uart16550_0/ip2intc_irpt] [get_bd_pins xlconcat_0/In0]

# Add AXI Timer
set axi_timer_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 axi_timer_0 ]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins axi_timer_0/s_axi_aclk]
connect_bd_net [get_bd_pins axi_timer_0/interrupt] [get_bd_pins xlconcat_0/In1]

# Add SPI Flash (optionally used by Linux)
set axi_quad_spi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 axi_quad_spi_0 ]
apply_board_connection -board_interface "spi_flash" -ip_intf "axi_quad_spi_0/SPI_0" -diagram "design_1"
connect_bd_net [get_bd_pins axi_quad_spi_0/ip2intc_irpt] [get_bd_pins xlconcat_0/In2]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins axi_quad_spi_0/ext_spi_clk]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins axi_quad_spi_0/s_axi_aclk]

# mem_intercon interface connections
connect_bd_intf_net -intf_net mem_intercon_m00_axi [get_bd_intf_pins mem_intercon/M00_AXI] [get_bd_intf_pins mig_7series_1/S_AXI]
connect_bd_intf_net -intf_net microblaze_1_m_axi_dc [get_bd_intf_pins microblaze_1/M_AXI_DC] [get_bd_intf_pins mem_intercon/S00_AXI]
connect_bd_intf_net -intf_net microblaze_1_m_axi_ic [get_bd_intf_pins microblaze_1/M_AXI_IC] [get_bd_intf_pins mem_intercon/S01_AXI]
connect_bd_intf_net -intf_net cdma_intercon_m01_axi [get_bd_intf_pins cdma_intercon/M01_AXI] [get_bd_intf_pins mem_intercon/S02_AXI]
connect_bd_intf_net -intf_net axi_pcie_1_m_axi [get_bd_intf_pins axi_pcie_1/M_AXI] [get_bd_intf_pins mem_intercon/S03_AXI]

# mem_intercon clocks
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins mem_intercon/M00_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins mem_intercon/ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins mem_intercon/S00_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins mem_intercon/S01_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins mem_intercon/S02_ACLK]
connect_bd_net -net axi_pcie_1_axi_aclk_out [get_bd_pins axi_pcie_1/axi_aclk_out] [get_bd_pins mem_intercon/S03_ACLK]

# cdma_intercon interface connections
connect_bd_intf_net -intf_net cdma_intercon_m00_axi [get_bd_intf_pins cdma_intercon/M00_AXI] [get_bd_intf_pins pcie_intercon/S00_AXI]
connect_bd_intf_net -intf_net cdma_intercon_m01_axi [get_bd_intf_pins cdma_intercon/M01_AXI] [get_bd_intf_pins mem_intercon/S02_AXI]
connect_bd_intf_net -intf_net axi_cdma_1_m_axi [get_bd_intf_pins axi_cdma_1/M_AXI] [get_bd_intf_pins cdma_intercon/S00_AXI]

# cdma_intercon clocks
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins cdma_intercon/ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins cdma_intercon/S00_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins cdma_intercon/M00_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins cdma_intercon/M01_ACLK]

# periph_intercon interface connections
connect_bd_intf_net -intf_net periph_intercon_m00_axi [get_bd_intf_pins periph_intercon/M00_AXI] [get_bd_intf_pins axi_cdma_1/S_AXI_LITE]
connect_bd_intf_net -intf_net periph_intercon_m01_axi [get_bd_intf_pins periph_intercon/M01_AXI] [get_bd_intf_pins axi_uart16550_0/S_AXI]
connect_bd_intf_net -intf_net periph_intercon_m02_axi [get_bd_intf_pins periph_intercon/M02_AXI] [get_bd_intf_pins axi_timer_0/S_AXI]
connect_bd_intf_net -intf_net periph_intercon_m03_axi [get_bd_intf_pins periph_intercon/M03_AXI] [get_bd_intf_pins axi_intc_0/s_axi]
connect_bd_intf_net -intf_net periph_intercon_m04_axi [get_bd_intf_pins periph_intercon/M04_AXI] [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
connect_bd_intf_net -intf_net periph_intercon_m05_axi [get_bd_intf_pins periph_intercon/M05_AXI] [get_bd_intf_pins pcie_intercon/S01_AXI]
connect_bd_intf_net -intf_net microblaze_1_m_axi_dp [get_bd_intf_pins microblaze_1/M_AXI_DP] [get_bd_intf_pins periph_intercon/S00_AXI]

# periph_intercon clocks
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins periph_intercon/ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins periph_intercon/S00_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins periph_intercon/M00_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins periph_intercon/M01_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins periph_intercon/M02_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins periph_intercon/M03_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins periph_intercon/M04_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins periph_intercon/M05_ACLK]

# pcie_intercon interface connections - S00_AXI and S01_AXI connections made previously
connect_bd_intf_net -intf_net pcie_intercon_m00_axi [get_bd_intf_pins pcie_intercon/M00_AXI] [get_bd_intf_pins axi_pcie_1/S_AXI]
connect_bd_intf_net -intf_net pcie_intercon_m01_axi [get_bd_intf_pins pcie_intercon/M01_AXI] [get_bd_intf_pins axi_pcie_1/S_AXI_CTL]

# pcie_intercon clocks
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins pcie_intercon/ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins pcie_intercon/S00_ACLK]
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins pcie_intercon/S01_ACLK]
connect_bd_net -net axi_pcie_1_axi_aclk_out [get_bd_pins axi_pcie_1/axi_aclk_out] [get_bd_pins pcie_intercon/M00_ACLK]
connect_bd_net -net axi_pcie_1_axi_ctl_aclk_out [get_bd_pins axi_pcie_1/axi_ctl_aclk_out] [get_bd_pins pcie_intercon/M01_ACLK]

# Microblaze interface connections
connect_bd_intf_net -intf_net microblaze_1_dlmb [get_bd_intf_pins microblaze_1/DLMB] [get_bd_intf_pins microblaze_1_local_memory/DLMB]
connect_bd_intf_net -intf_net microblaze_1_ilmb [get_bd_intf_pins microblaze_1/ILMB] [get_bd_intf_pins microblaze_1_local_memory/ILMB]
connect_bd_intf_net -intf_net microblaze_1_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_1/DEBUG]

# proc_sys_reset_0 connections
connect_bd_net -net axi_pcie_1_axi_aclk_out [get_bd_pins axi_pcie_1/axi_aclk_out] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net -net pcie_reset_n [get_bd_ports perst_n] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net -net axi_pcie_1_mmcm_lock [get_bd_pins axi_pcie_1/mmcm_lock] [get_bd_pins proc_sys_reset_0/dcm_locked]
connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins mem_intercon/S03_ARESETN]
connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins pcie_intercon/M00_ARESETN]

# proc_sys_reset_1 connections
connect_bd_net -net axi_pcie_1_axi_ctl_aclk_out [get_bd_pins axi_pcie_1/axi_ctl_aclk_out] [get_bd_pins proc_sys_reset_1/slowest_sync_clk]
connect_bd_net -net pcie_reset_n [get_bd_ports perst_n] [get_bd_pins proc_sys_reset_1/ext_reset_in]
connect_bd_net -net axi_pcie_1_mmcm_lock [get_bd_pins axi_pcie_1/mmcm_lock] [get_bd_pins proc_sys_reset_1/dcm_locked]
connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins pcie_intercon/M01_ARESETN]

# proc_sys_reset_2 connections
connect_bd_net -net mig_7series_1_ui_clk [get_bd_pins mig_7series_1/ui_clk] [get_bd_pins proc_sys_reset_2/slowest_sync_clk]
connect_bd_net -net mig_7series_1_ui_clk_sync_rst [get_bd_pins mig_7series_1/ui_clk_sync_rst] [get_bd_pins proc_sys_reset_2/ext_reset_in]
connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins proc_sys_reset_2/mb_debug_sys_rst]
connect_bd_net -net mig_7series_1_mmcm_locked [get_bd_pins mig_7series_1/mmcm_locked] [get_bd_pins proc_sys_reset_2/dcm_locked]
connect_bd_net -net proc_sys_reset_2_mb_reset [get_bd_pins proc_sys_reset_2/mb_reset] [get_bd_pins microblaze_1/Reset]
connect_bd_net -net proc_sys_reset_2_mb_reset [get_bd_pins proc_sys_reset_2/mb_reset] [get_bd_pins axi_intc_0/processor_rst]
connect_bd_net -net proc_sys_reset_2_bus_struct_reset [get_bd_pins proc_sys_reset_2/bus_struct_reset] [get_bd_pins microblaze_1_local_memory/LMB_Rst]
connect_bd_net -net proc_sys_reset_2_interconnect_aresetn [get_bd_pins proc_sys_reset_2/interconnect_aresetn] [get_bd_pins mem_intercon/ARESETN]
connect_bd_net -net proc_sys_reset_2_interconnect_aresetn [get_bd_pins proc_sys_reset_2/interconnect_aresetn] [get_bd_pins cdma_intercon/ARESETN]
connect_bd_net -net proc_sys_reset_2_interconnect_aresetn [get_bd_pins proc_sys_reset_2/interconnect_aresetn] [get_bd_pins periph_intercon/ARESETN]
connect_bd_net -net proc_sys_reset_2_interconnect_aresetn [get_bd_pins proc_sys_reset_2/interconnect_aresetn] [get_bd_pins pcie_intercon/ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins mem_intercon/S00_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins mem_intercon/S01_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins mem_intercon/S02_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins cdma_intercon/S00_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins cdma_intercon/M00_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins cdma_intercon/M01_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins periph_intercon/S00_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins periph_intercon/M00_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins periph_intercon/M01_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins periph_intercon/M02_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins periph_intercon/M03_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins periph_intercon/M04_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins periph_intercon/M05_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins pcie_intercon/S00_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins pcie_intercon/S01_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins axi_cdma_1/s_axi_lite_aresetn]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins axi_uart16550_0/s_axi_aresetn]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins axi_timer_0/s_axi_aresetn]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins axi_intc_0/s_axi_aresetn]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins axi_quad_spi_0/s_axi_aresetn]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins mem_intercon/M00_ARESETN]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins mig_7series_1/aresetn]

# Create external port connections
connect_bd_net -net pcie_reset_n [get_bd_ports perst_n] [get_bd_pins axi_pcie_1/axi_aresetn]
connect_bd_net -net axi_pcie_1_mmcm_lock [get_bd_ports mmcm_lock] [get_bd_pins axi_pcie_1/mmcm_lock]
connect_bd_net -net mig_7series_1_init_calib_complete [get_bd_ports init_calib_complete] [get_bd_pins mig_7series_1/init_calib_complete]
connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins mig_7series_1/sys_rst]

# Create constants for AC701 SFP MGT CLK SEL0/1 for selection of FMC GTX clock
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 sfp_mgt_clk_sel0
create_bd_port -dir O -from 0 -to 0 sfp_mgt_clk_sel0
connect_bd_net [get_bd_pins /sfp_mgt_clk_sel0/dout] [get_bd_ports sfp_mgt_clk_sel0]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 sfp_mgt_clk_sel1
create_bd_port -dir O -from 0 -to 0 sfp_mgt_clk_sel1
connect_bd_net [get_bd_pins /sfp_mgt_clk_sel1/dout] [get_bd_ports sfp_mgt_clk_sel1]

# AXI PCIe address segments
create_bd_addr_seg -range 1G -offset 0x80000000 [get_bd_addr_spaces axi_pcie_1/M_AXI] [get_bd_addr_segs mig_7series_1/memmap/memaddr] DDR_SEG

# CDMA address segments
create_bd_addr_seg -range 64M -offset 0x50000000 [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs axi_pcie_1/S_AXI_CTL/CTL0] PCI_CTL_SEG
create_bd_addr_seg -range 256M -offset 0x60000000 [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs axi_pcie_1/S_AXI/BAR0] PCI_BAR0_SEG
create_bd_addr_seg -range 1G -offset 0x80000000 [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs mig_7series_1/memmap/memaddr] DDR_SEG

# Microblaze address segments
create_bd_addr_seg -range 128K -offset 0x0 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs microblaze_1_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] LOCAL_MEM_SEG
create_bd_addr_seg -range 64M -offset 0x50000000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_pcie_1/S_AXI_CTL/CTL0] PCI_CTL_SEG
create_bd_addr_seg -range 256M -offset 0x60000000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_pcie_1/S_AXI/BAR0] PCI_BAR0_SEG
create_bd_addr_seg -range 1G -offset 0x80000000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs mig_7series_1/memmap/memaddr] DDR_SEG
create_bd_addr_seg -range 64K -offset 0x44A00000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_cdma_1/S_AXI_LITE/Reg] CDMA_SEG
create_bd_addr_seg -range 64K -offset 0x44A10000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_uart16550_0/S_AXI/Reg] UART_SEG
create_bd_addr_seg -range 64K -offset 0x41C00000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_timer_0/S_AXI/Reg] TIMER_SEG
create_bd_addr_seg -range 64K -offset 0x41200000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_intc_0/S_AXI/Reg] INTC_SEG
create_bd_addr_seg -range 64K -offset 0x44A20000 [get_bd_addr_spaces microblaze_1/Data] [get_bd_addr_segs axi_quad_spi_0/AXI_LITE/Reg] SPI_FLASH_SEG
create_bd_addr_seg -range 128K -offset 0x0 [get_bd_addr_spaces microblaze_1/Instruction] [get_bd_addr_segs microblaze_1_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] LOCAL_MEM_SEG
create_bd_addr_seg -range 1G -offset 0x80000000 [get_bd_addr_spaces microblaze_1/Instruction] [get_bd_addr_segs mig_7series_1/memmap/memaddr] DDR_SEG

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design
