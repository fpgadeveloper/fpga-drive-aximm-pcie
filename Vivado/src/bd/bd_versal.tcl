################################################################
# Block design build script for Versal designs
################################################################

# This design follows the Versal PL QDMA Root Port CED from 2025.2.1 but it has been
# adapted to work with the Opsero FPGA Drive FMC Gen4 and M.2 M-key Stack FMCs.
#
# Information on the CEDs:
# - VCK190 CED: 1x PCIe Gen4 (16GT/s) 8-lane design
# - VPK120 CED: 1x PCIe Gen5 (32GT/s) 4-lane design
#
# Our designs deviate from the CEDs in the following ways:
# - VCK190_FMCP1/2, VMK180_FMCP1/2: 2x PCIe Gen4 (16GT/s) 4-lane
# - VEK280: 1x PCIe Gen5 (32GT/s) 4-lane
# - VHK158, VPK120, VPK180: 1x PCIe Gen5 (32GT/s) 4-lane

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

create_bd_design $block_name

current_bd_design $block_name

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

# Returns true if str contains substr
proc str_contains {str substr} {
  if {[string first $substr $str] == -1} {
    return 0
  } else {
    return 1
  }
}

# Target board checks
set is_vck190 [str_contains $target "vck190"]
set is_vmk180 [str_contains $target "vmk180"]
set is_vek280 [str_contains $target "vek280"]
set is_vpk120 [str_contains $target "vpk120"]
set is_vpk180 [str_contains $target "vpk180"]
set is_vhk158 [str_contains $target "vhk158"]

# Work out the ref board label
set ref_board [string toupper $target]
set underscore_pos [string first "_" $ref_board]
if {$underscore_pos != -1} {
  set ref_board [string range $ref_board 0 [expr {$underscore_pos - 1}]]
}

# PCIe LOCs
if {$dual_design} {
  set pcie_blk_locn [list [dict get $gt_loc_dict $target 0 pcie] [dict get $gt_loc_dict $target 1 pcie]]
} else {
  set pcie_blk_locn [list [dict get $gt_loc_dict $target 0 pcie] ]
}

# BAR addresses and sizes
set bar_addr { 0x000A8000000 0x000B0000000 }
set bar_size { 128M 256M }
set qdma_cfg_addr { 0x400000000 0x440000000 }

# List of interrupt pins
set intr_list {}

# Add the CIPS
create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0

# Configure the CIPS using automation feature
if {$is_vpk120 || $is_vek280 || $is_vpk180} {
  apply_bd_automation -rule xilinx.com:bd_rule:cips -config { \
    board_preset {Yes} \
    boot_config {Custom} \
    configure_noc {Add new AXI NoC} \
    debug_config {JTAG} \
    design_flow {Full System} \
    mc_type {LPDDR} \
    num_mc_ddr {None} \
    num_mc_lpddr {1} \
    pl_clocks {None} \
    pl_resets {None} \
  }  [get_bd_cells versal_cips_0]
} else {
  apply_bd_automation -rule xilinx.com:bd_rule:cips -config { \
    board_preset {Yes} \
    boot_config {Custom} \
    configure_noc {Add new AXI NoC} \
    debug_config {JTAG} \
    design_flow {Full System} \
    mc_type {DDR} \
    num_mc_ddr {1} \
    num_mc_lpddr {None} \
    pl_clocks {None} \
    pl_resets {None} \
  }  [get_bd_cells versal_cips_0]
}

# Extra config for this design:
# PL CLK0 output clock enabled 250MHz
# Enable interrupts: IRO0-IRQ5
# NoC interfaces: PS to NoC Interface 0 + 1, NoC to PS Interface 0
# PS-PL interfaces: PL Resets 1, Enable M_AXI_FPD 128 + M_AXI_LPD 128

if {$is_vpk120 || $is_vpk180} {
  set_property -dict [list \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
      DEBUG_MODE {JTAG} \
      DESIGN_MODE {1} \
      DEVICE_INTEGRITY_MODE {Sysmon temperature voltage and external IO monitoring} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {250} \
      PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}} \
      PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
      PMC_QSPI_PERIPHERAL_DATA_MODE {x4} \
      PMC_QSPI_PERIPHERAL_ENABLE {1} \
      PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
      PMC_REF_CLK_FREQMHZ {33.3333} \
      PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO {PMC_MIO 26 .. 36}}} \
      PMC_SD1_SLOT_TYPE {SD 3.0} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI0_MASTER {A72} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_HSDP_EGRESS_TRAFFIC {JTAG} \
      PS_HSDP_INGRESS_TRAFFIC {JTAG} \
      PS_HSDP_MODE {NONE} \
      PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} \
      PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
      PS_I2CSYSMON_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 39 .. 40}}} \
      PS_IRQ_USAGE {{CH0 1} {CH1 1} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 1} {CH3 1} {CH4 1} {CH5 1} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} \
      PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_PCIE_EP_RESET1_IO {PS_MIO 18} \
      PS_PCIE_EP_RESET2_IO {PS_MIO 19} \
      PS_PCIE_RESET {ENABLE 1} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_AXI_NOC0 {1} \
      PS_USE_FPD_AXI_NOC1 {1} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
      PS_USE_M_AXI_FPD {1} \
      PS_USE_M_AXI_LPD {1} \
      PS_USE_NOC_FPD_AXI0 {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_PMCPL_CLK1 {0} \
      PS_USE_PMCPL_CLK2 {0} \
      PS_USE_PMCPL_CLK3 {0} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_INTERFACE_TO_USE {I2C} \
      SMON_PMBUS_ADDRESS {0x18} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] [get_bd_cells versal_cips_0]
} elseif {$is_vek280} {
  set_property -dict [list \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
      DEBUG_MODE {JTAG} \
      DESIGN_MODE {1} \
      DEVICE_INTEGRITY_MODE {Sysmon temperature voltage and external IO monitoring} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {250} \
      PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}} \
      PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}} \
      PMC_MIO12 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_MIO38 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_OSPI_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
      PMC_REF_CLK_FREQMHZ {33.3333} \
      PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO {PMC_MIO 26 .. 36}}} \
      PMC_SD1_SLOT_TYPE {SD 3.0} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
      PS_CAN0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 14 .. 15}}} \
      PS_CAN1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 16 .. 17}}} \
      PS_CRL_CAN0_REF_CTRL_FREQMHZ {160} \
      PS_CRL_CAN1_REF_CTRL_FREQMHZ {160} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI0_MASTER {A72} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_HSDP_EGRESS_TRAFFIC {JTAG} \
      PS_HSDP_INGRESS_TRAFFIC {JTAG} \
      PS_HSDP_MODE {NONE} \
      PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} \
      PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
      PS_I2CSYSMON_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 39 .. 40}}} \
      PS_IRQ_USAGE {{CH0 1} {CH1 1} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 1} {CH3 1} {CH4 1} {CH5 1} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} \
      PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_PCIE_EP_RESET1_IO {PS_MIO 18} \
      PS_PCIE_EP_RESET2_IO {PS_MIO 19} \
      PS_PCIE_RESET {ENABLE 1} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_AXI_NOC0 {1} \
      PS_USE_FPD_AXI_NOC1 {1} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
      PS_USE_M_AXI_FPD {1} \
      PS_USE_M_AXI_LPD {1} \
      PS_USE_NOC_FPD_AXI0 {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_PMCPL_CLK1 {0} \
      PS_USE_PMCPL_CLK2 {0} \
      PS_USE_PMCPL_CLK3 {0} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_INTERFACE_TO_USE {I2C} \
      SMON_PMBUS_ADDRESS {0x18} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] [get_bd_cells versal_cips_0]
} elseif {$is_vhk158} {
  set_property -dict [list \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
      DEBUG_MODE {JTAG} \
      DESIGN_MODE {1} \
      DEVICE_INTEGRITY_MODE {Sysmon temperature voltage and external IO monitoring} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {250} \
      PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}} \
      PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}} \
      PMC_MIO12 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_OSPI_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
      PMC_REF_CLK_FREQMHZ {33.333} \
      PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x2A} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x25} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO {PMC_MIO 26 .. 36}}} \
      PMC_SD1_SLOT_TYPE {SD 3.0 AUTODIR} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI0_MASTER {A72} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_HSDP_EGRESS_TRAFFIC {JTAG} \
      PS_HSDP_INGRESS_TRAFFIC {JTAG} \
      PS_HSDP_MODE {NONE} \
      PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} \
      PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
      PS_I2CSYSMON_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 39 .. 40}}} \
      PS_IRQ_USAGE {{CH0 1} {CH1 1} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 1} {CH3 1} {CH4 1} {CH5 1} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} \
      PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_PCIE_EP_RESET1_IO {PS_MIO 18} \
      PS_PCIE_EP_RESET2_IO {PS_MIO 19} \
      PS_PCIE_RESET {ENABLE 1} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_AXI_NOC0 {1} \
      PS_USE_FPD_AXI_NOC1 {1} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
      PS_USE_M_AXI_FPD {1} \
      PS_USE_M_AXI_LPD {1} \
      PS_USE_NOC_FPD_AXI0 {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_PMCPL_CLK1 {0} \
      PS_USE_PMCPL_CLK2 {0} \
      PS_USE_PMCPL_CLK3 {0} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_INTERFACE_TO_USE {I2C} \
      SMON_PMBUS_ADDRESS {0x18} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] [get_bd_cells versal_cips_0]
} else {
  set_property -dict [list \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
      DEBUG_MODE {JTAG} \
      DESIGN_MODE {1} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {250} \
      PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}} \
      PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_OSPI_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
      PMC_QSPI_COHERENCY {0} \
      PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
      PMC_QSPI_PERIPHERAL_DATA_MODE {x4} \
      PMC_QSPI_PERIPHERAL_ENABLE {1} \
      PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
      PMC_REF_CLK_FREQMHZ {33.3333} \
      PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
      PMC_SD1_COHERENCY {0} \
      PMC_SD1_DATA_TRANSFER_MODE {8Bit} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO {PMC_MIO 26 .. 36}}} \
      PMC_SD1_SLOT_TYPE {SD 3.0} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
      PS_CAN1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 40 .. 41}}} \
      PS_CRL_CAN1_REF_CTRL_FREQMHZ {160} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_ENET1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 12 .. 23}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI0_MASTER {A72} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_HSDP_EGRESS_TRAFFIC {JTAG} \
      PS_HSDP_INGRESS_TRAFFIC {JTAG} \
      PS_HSDP_MODE {NONE} \
      PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} \
      PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
      PS_IRQ_USAGE {{CH0 1} {CH1 1} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 1} {CH3 1} {CH4 1} {CH5 1} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} \
      PS_MIO19 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO21 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_PCIE_EP_RESET1_IO {PMC_MIO 38} \
      PS_PCIE_EP_RESET2_IO {PMC_MIO 39} \
      PS_PCIE_RESET {ENABLE 1} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_AXI_NOC0 {1} \
      PS_USE_FPD_AXI_NOC1 {1} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
      PS_USE_M_AXI_FPD {1} \
      PS_USE_M_AXI_LPD {1} \
      PS_USE_NOC_FPD_AXI0 {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_PMCPL_CLK1 {0} \
      PS_USE_PMCPL_CLK2 {0} \
      PS_USE_PMCPL_CLK3 {0} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] [get_bd_cells versal_cips_0]
}

# NoC connections and config
# S00_AXI - FPD_CCI_NOC_0 - PS Cache Coh - 0
# S01_AXI - FPD_CCI_NOC_1 - PS Cache Coh - 1
# S02_AXI - FPD_CCI_NOC_2 - PS Cache Coh - 2
# S03_AXI - FPD_CCI_NOC_3 - PS Cache Coh - 3
# S04_AXI - LPD_AXI_NOC_0 - PS LPD       - 2
# S05_AXI - PMC_NOC_AXI_0 - PS PMC       - M00_AXI + 1
# S06_AXI - FPD_AXI_NOC_1 - PS Non-Coh   - 0
# S07_AXI - FPD_AXI_NOC_0 - PS Non-Coh   - 0
# S08_AXI - BRIDGE        - PL           - 3

# Configure the NoC
set_property -dict [list \
  CONFIG.MC_CHAN_REGION1 {DDR_CH1} \
  CONFIG.NUM_CLKS {10} \
  CONFIG.NUM_MI {1} \
  CONFIG.NUM_SI {9} \
] [get_bd_cells axi_noc_0]
set_property -dict [list CONFIG.CATEGORY {ps_nci_phy}] [get_bd_intf_pins /axi_noc_0/M00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }}] [get_bd_intf_pins /axi_noc_0/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }}] [get_bd_intf_pins /axi_noc_0/S01_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }}] [get_bd_intf_pins /axi_noc_0/S02_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }}] [get_bd_intf_pins /axi_noc_0/S03_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {MC_3 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }}] [get_bd_intf_pins /axi_noc_0/S04_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4} initial_boot {true} } MC_2 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }}] [get_bd_intf_pins /axi_noc_0/S05_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }}] [get_bd_intf_pins /axi_noc_0/S06_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }}] [get_bd_intf_pins /axi_noc_0/S07_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4} }}] [get_bd_intf_pins /axi_noc_0/S08_AXI]

# Connect FPD AXI NOC interfaces and clocks to NoC
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_AXI_NOC_0] [get_bd_intf_pins axi_noc_0/S06_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_AXI_NOC_1] [get_bd_intf_pins axi_noc_0/S07_AXI]
connect_bd_net [get_bd_pins versal_cips_0/fpd_axi_noc_axi0_clk] [get_bd_pins axi_noc_0/aclk6]
connect_bd_net [get_bd_pins versal_cips_0/fpd_axi_noc_axi1_clk] [get_bd_pins axi_noc_0/aclk7]
connect_bd_net [get_bd_pins versal_cips_0/noc_fpd_axi_axi0_clk] [get_bd_pins axi_noc_0/aclk8]

# Connect NoC's AXI Master interface to the CIPS
connect_bd_intf_net [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins versal_cips_0/NOC_FPD_AXI_0]

# QDMA support block
proc create_qdma_support { index } {

  global pcie_blk_locn
  global target
  global is_vpk120
  global is_vpk180
  global is_vck190
  global is_vmk180
  global is_vek280
  global is_vhk158
  set hier_obj [create_bd_cell -type hier qdma_support_$index]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_cq

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_rc

  if {$is_vpk120 || $is_vek280 || $is_vpk180 || $is_vhk158} {
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie5_cfg_control_rtl:1.0 pcie_cfg_control
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie5_cfg_status_rtl:1.0 pcie_cfg_status
  } else {
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_control_rtl:1.0 pcie_cfg_control
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie4_cfg_status_rtl:1.0 pcie_cfg_status
  }

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie_cfg_fc_rtl:1.1 pcie_cfg_fc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie3_cfg_interrupt_rtl:1.0 pcie_cfg_interrupt

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie3_cfg_msg_received_rtl:1.0 pcie_cfg_mesg_rcvd

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie3_cfg_mesg_tx_rtl:1.0 pcie_cfg_mesg_tx

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_mgmt_rtl:1.0 pcie_cfg_mgmt

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pcie_mgt

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie3_transmit_fc_rtl:1.0 pcie_transmit_fc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_cc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_rq


  # Create pins
  create_bd_pin -dir O -from 5 -to 0 pcie_ltssm_state
  create_bd_pin -dir O phy_rdy_out
  create_bd_pin -dir I -type rst sys_reset
  create_bd_pin -dir O -type clk user_clk
  create_bd_pin -dir O user_lnk_up
  create_bd_pin -dir O -type rst user_reset

  # Create instance: bufg_gt_sysclk, and set properties
  set bufg_gt_sysclk [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf bufg_gt_sysclk ]
  set_property -dict [ list \
   CONFIG.C_BUFG_GT_SYNC {true} \
   CONFIG.C_BUF_TYPE {BUFG_GT} \
 ] $bufg_gt_sysclk

  # Create instance: pcie, and set properties
  global ref_board
  set pcie [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_versal pcie ]
  if {$is_vck190 | $is_vmk180} {
    set_property -dict [ list \
      CONFIG.AXISTEN_IF_CQ_ALIGNMENT_MODE {Address_Aligned} \
      CONFIG.AXISTEN_IF_EXT_512_RQ_STRADDLE {true} \
      CONFIG.AXISTEN_IF_RQ_ALIGNMENT_MODE {DWORD_Aligned} \
      CONFIG.PF0_DEVICE_ID {B048} \
      CONFIG.PF0_INTERRUPT_PIN {INTA} \
      CONFIG.PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {true} \
      CONFIG.PF0_REVISION_ID {00} \
      CONFIG.PF0_SRIOV_VF_DEVICE_ID {C048} \
      CONFIG.PF0_SUBSYSTEM_ID {0007} \
      CONFIG.PF0_Use_Class_Code_Lookup_Assistant {false} \
      CONFIG.PF1_DEVICE_ID {9011} \
      CONFIG.PF1_REVISION_ID {00} \
      CONFIG.PF1_SUBSYSTEM_ID {0007} \
      CONFIG.PF1_SUBSYSTEM_VENDOR_ID {10EE} \
      CONFIG.PF1_Use_Class_Code_Lookup_Assistant {false} \
      CONFIG.PF2_DEVICE_ID {B248} \
      CONFIG.PF2_REVISION_ID {00} \
      CONFIG.PF2_SUBSYSTEM_ID {0007} \
      CONFIG.PF2_SUBSYSTEM_VENDOR_ID {10EE} \
      CONFIG.PF2_Use_Class_Code_Lookup_Assistant {false} \
      CONFIG.PF3_DEVICE_ID {B348} \
      CONFIG.PF3_REVISION_ID {00} \
      CONFIG.PF3_SUBSYSTEM_ID {0007} \
      CONFIG.PF3_SUBSYSTEM_VENDOR_ID {10EE} \
      CONFIG.PF3_Use_Class_Code_Lookup_Assistant {false} \
      CONFIG.PF4_DEVICE_ID {B448} \
      CONFIG.PF5_DEVICE_ID {B548} \
      CONFIG.PF6_DEVICE_ID {B648} \
      CONFIG.PF7_DEVICE_ID {B748} \
      CONFIG.PL_DISABLE_LANE_REVERSAL {false} \
      CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {16.0_GT/s} \
      CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X4} \
      CONFIG.REF_CLK_FREQ {100_MHz} \
      CONFIG.acs_ext_cap_enable {false} \
      CONFIG.axisten_freq {250} \
      CONFIG.axisten_if_enable_client_tag {true} \
      CONFIG.axisten_if_enable_msg_route_override {TRUE} \
      CONFIG.axisten_if_width {256_bit} \
      CONFIG.cfg_ext_if {false} \
      CONFIG.cfg_mgmt_if {true} \
      CONFIG.copy_pf0 {true} \
      CONFIG.dedicate_perst {false} \
      CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
      CONFIG.disable_double_pipe {NO} \
      CONFIG.en_dbg_descramble {false} \
      CONFIG.en_ext_clk {FALSE} \
      CONFIG.en_l23_entry {false} \
      CONFIG.en_parity {false} \
      CONFIG.enable_auto_rxeq {False} \
      CONFIG.enable_ccix {FALSE} \
      CONFIG.enable_dvsec {FALSE} \
      CONFIG.enable_gen4 {true} \
      CONFIG.enable_gtwizard {true} \
      CONFIG.enable_ibert {false} \
      CONFIG.enable_jtag_dbg {false} \
      CONFIG.ext_pcie_cfg_space_enabled {false} \
      CONFIG.extended_tag_field {true} \
      CONFIG.insert_cips {false} \
      CONFIG.legacy_ext_pcie_cfg_space_enabled {false} \
      CONFIG.mode_selection {Advanced} \
      CONFIG.pcie_blk_locn [lindex $pcie_blk_locn $index] \
      CONFIG.pf0_ari_enabled {false} \
      CONFIG.pf0_bar0_64bit {true} \
      CONFIG.pf0_bar0_enabled {true} \
      CONFIG.pf0_bar0_prefetchable {true} \
      CONFIG.pf0_bar0_scale {Terabytes} \
      CONFIG.pf0_bar0_size {16} \
      CONFIG.pf0_bar2_enabled {false} \
      CONFIG.pf0_bar4_enabled {false} \
      CONFIG.pf0_base_class_menu {Bridge_device} \
      CONFIG.pf0_class_code_base {06} \
      CONFIG.pf0_class_code_interface {00} \
      CONFIG.pf0_class_code_sub {04} \
      CONFIG.pf0_dll_feature_cap_enabled {true} \
      CONFIG.pf0_margining_cap_enabled {true} \
      CONFIG.pf0_msi_enabled {false} \
      CONFIG.pf0_msix_enabled {false} \
      CONFIG.pf0_pl16_cap_enabled {true} \
      CONFIG.pf0_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf1_base_class_menu {Bridge_device} \
      CONFIG.pf1_class_code_base {06} \
      CONFIG.pf1_class_code_interface {00} \
      CONFIG.pf1_class_code_sub {04} \
      CONFIG.pf1_msix_enabled {false} \
      CONFIG.pf1_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf1_vendor_id {10EE} \
      CONFIG.pf2_base_class_menu {Bridge_device} \
      CONFIG.pf2_class_code_base {06} \
      CONFIG.pf2_class_code_interface {00} \
      CONFIG.pf2_class_code_sub {04} \
      CONFIG.pf2_msix_enabled {false} \
      CONFIG.pf2_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf2_vendor_id {10EE} \
      CONFIG.pf3_base_class_menu {Bridge_device} \
      CONFIG.pf3_class_code_base {06} \
      CONFIG.pf3_class_code_interface {00} \
      CONFIG.pf3_class_code_sub {04} \
      CONFIG.pf3_msix_enabled {false} \
      CONFIG.pf3_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf3_vendor_id {10EE} \
      CONFIG.pf4_base_class_menu {Bridge_device} \
      CONFIG.pf4_class_code_base {06} \
      CONFIG.pf4_class_code_sub {04} \
      CONFIG.pf4_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf5_base_class_menu {Bridge_device} \
      CONFIG.pf5_class_code_base {06} \
      CONFIG.pf5_class_code_sub {04} \
      CONFIG.pf5_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf6_base_class_menu {Bridge_device} \
      CONFIG.pf6_class_code_base {06} \
      CONFIG.pf6_class_code_sub {04} \
      CONFIG.pf6_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf7_base_class_menu {Bridge_device} \
      CONFIG.pf7_class_code_base {06} \
      CONFIG.pf7_class_code_sub {04} \
      CONFIG.pf7_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pipe_line_stage {1} \
      CONFIG.pipe_sim {false} \
      CONFIG.plltype {LCPLL} \
      CONFIG.sys_reset_polarity {ACTIVE_LOW} \
      CONFIG.type1_membase_memlimit_enable {Enabled} \
      CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} \
      CONFIG.userclk2_freq {250} \
      CONFIG.vendor_id {10EE} \
  ] $pcie
  } else {
    set_property -dict [list \
      CONFIG.AXISTEN_IF_CQ_ALIGNMENT_MODE {Address_Aligned} \
      CONFIG.AXISTEN_IF_RQ_ALIGNMENT_MODE {DWORD_Aligned} \
      CONFIG.PF0_AER_CAP_ECRC_GEN_AND_CHECK_CAPABLE {false} \
      CONFIG.PF0_DEVICE_ID {B0D4} \
      CONFIG.PF0_INTERRUPT_PIN {INTA} \
      CONFIG.PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {true} \
      CONFIG.PF0_REVISION_ID {00} \
      CONFIG.PF0_SRIOV_VF_DEVICE_ID {C034} \
      CONFIG.PF0_SUBSYSTEM_ID {0007} \
      CONFIG.PF1_DEVICE_ID {913F} \
      CONFIG.PF1_MSI_CAP_MULTIMSGCAP {1_vector} \
      CONFIG.PF1_REVISION_ID {00} \
      CONFIG.PF1_SUBSYSTEM_ID {0007} \
      CONFIG.PF1_SUBSYSTEM_VENDOR_ID {10EE} \
      CONFIG.PF2_DEVICE_ID {B2D4} \
      CONFIG.PF2_MSI_CAP_MULTIMSGCAP {1_vector} \
      CONFIG.PF2_REVISION_ID {00} \
      CONFIG.PF2_SUBSYSTEM_ID {0007} \
      CONFIG.PF2_SUBSYSTEM_VENDOR_ID {10EE} \
      CONFIG.PF3_DEVICE_ID {B3D4} \
      CONFIG.PF3_MSI_CAP_MULTIMSGCAP {1_vector} \
      CONFIG.PF3_REVISION_ID {00} \
      CONFIG.PF3_SUBSYSTEM_ID {0007} \
      CONFIG.PF3_SUBSYSTEM_VENDOR_ID {10EE} \
      CONFIG.PF4_DEVICE_ID {B4D4} \
      CONFIG.PF5_DEVICE_ID {B5D4} \
      CONFIG.PF6_DEVICE_ID {B6D4} \
      CONFIG.PF7_DEVICE_ID {B7D4} \
      CONFIG.PL_DISABLE_LANE_REVERSAL {TRUE} \
      CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {32.0_GT/s} \
      CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X4} \
      CONFIG.REF_CLK_FREQ {100_MHz} \
      CONFIG.acs_ext_cap_enable {false} \
      CONFIG.all_speeds_all_sides {NO} \
      CONFIG.axisten_freq {250} \
      CONFIG.axisten_if_enable_client_tag {true} \
      CONFIG.axisten_if_enable_msg_route_override {TRUE} \
      CONFIG.axisten_if_width {512_bit} \
      CONFIG.cfg_ext_if {false} \
      CONFIG.cfg_mgmt_if {true} \
      CONFIG.copy_pf0 {true} \
      CONFIG.coreclk_freq {500} \
      CONFIG.dedicate_perst {false} \
      CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
      CONFIG.en_dbg_descramble {false} \
      CONFIG.en_ext_clk {FALSE} \
      CONFIG.en_l23_entry {false} \
      CONFIG.en_parity {false} \
      CONFIG.en_transceiver_status_ports {false} \
      CONFIG.enable_auto_rxeq {False} \
      CONFIG.enable_ccix {FALSE} \
      CONFIG.enable_dvsec {FALSE} \
      CONFIG.enable_gen4 {true} \
      CONFIG.enable_gtwizard {true} \
      CONFIG.enable_ibert {false} \
      CONFIG.enable_jtag_dbg {false} \
      CONFIG.enable_more_clk {false} \
      CONFIG.ext_pcie_cfg_space_enabled {false} \
      CONFIG.extended_tag_field {true} \
      CONFIG.insert_cips {false} \
      CONFIG.lane_order {Bottom} \
      CONFIG.legacy_ext_pcie_cfg_space_enabled {false} \
      CONFIG.mode_selection {Advanced} \
      CONFIG.pcie_blk_locn [lindex $pcie_blk_locn $index] \
      CONFIG.pcie_link_debug {false} \
      CONFIG.pcie_link_debug_axi4_st {false} \
      CONFIG.pf0_ari_enabled {false} \
      CONFIG.pf0_bar0_64bit {true} \
      CONFIG.pf0_bar0_enabled {true} \
      CONFIG.pf0_bar0_prefetchable {false} \
      CONFIG.pf0_bar0_scale {Terabytes} \
      CONFIG.pf0_bar0_size {16} \
      CONFIG.pf0_bar2_64bit {true} \
      CONFIG.pf0_bar2_enabled {true} \
      CONFIG.pf0_bar2_prefetchable {false} \
      CONFIG.pf0_bar2_scale {Kilobytes} \
      CONFIG.pf0_bar2_size {4} \
      CONFIG.pf0_bar2_type {Memory} \
      CONFIG.pf0_bar4_enabled {false} \
      CONFIG.pf0_base_class_menu {Bridge_device} \
      CONFIG.pf0_class_code_base {06} \
      CONFIG.pf0_class_code_interface {00} \
      CONFIG.pf0_class_code_sub {0A} \
      CONFIG.pf0_expansion_rom_enabled {false} \
      CONFIG.pf0_msi_enabled {false} \
      CONFIG.pf0_msix_enabled {false} \
      CONFIG.pf0_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf0_vc_cap_enabled {true} \
      CONFIG.pf1_base_class_menu {Bridge_device} \
      CONFIG.pf1_class_code_base {06} \
      CONFIG.pf1_class_code_interface {00} \
      CONFIG.pf1_class_code_sub {0A} \
      CONFIG.pf1_msix_enabled {false} \
      CONFIG.pf1_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf1_vendor_id {10EE} \
      CONFIG.pf2_base_class_menu {Bridge_device} \
      CONFIG.pf2_class_code_base {06} \
      CONFIG.pf2_class_code_interface {00} \
      CONFIG.pf2_class_code_sub {0A} \
      CONFIG.pf2_msix_enabled {false} \
      CONFIG.pf2_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf2_vendor_id {10EE} \
      CONFIG.pf3_base_class_menu {Bridge_device} \
      CONFIG.pf3_class_code_base {06} \
      CONFIG.pf3_class_code_interface {00} \
      CONFIG.pf3_class_code_sub {0A} \
      CONFIG.pf3_msix_enabled {false} \
      CONFIG.pf3_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf3_vendor_id {10EE} \
      CONFIG.pf4_base_class_menu {Bridge_device} \
      CONFIG.pf4_class_code_base {06} \
      CONFIG.pf4_class_code_sub {0A} \
      CONFIG.pf4_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf5_base_class_menu {Bridge_device} \
      CONFIG.pf5_class_code_base {06} \
      CONFIG.pf5_class_code_sub {0A} \
      CONFIG.pf5_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf6_base_class_menu {Bridge_device} \
      CONFIG.pf6_class_code_base {06} \
      CONFIG.pf6_class_code_sub {0A} \
      CONFIG.pf6_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pf7_base_class_menu {Bridge_device} \
      CONFIG.pf7_class_code_base {06} \
      CONFIG.pf7_class_code_sub {0A} \
      CONFIG.pf7_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
      CONFIG.pipe_line_stage {2} \
      CONFIG.pipe_sim {false} \
      CONFIG.replace_uram_with_bram {false} \
      CONFIG.sys_reset_polarity {ACTIVE_LOW} \
      CONFIG.type1_membase_memlimit_enable {Enabled} \
      CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} \
      CONFIG.vendor_id {10EE} \
      CONFIG.warm_reboot_sbr_fix {false} \
      CONFIG.xlnx_ref_board $ref_board \
    ] $pcie
  }
  # Create instance: pcie_phy, and set properties
  set pcie_phy [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_phy_versal pcie_phy ]
  if {$is_vck190 | $is_vmk180} {
    set_property -dict [ list \
      CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {16.0_GT/s} \
      CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X4} \
      CONFIG.aspm {No_ASPM} \
      CONFIG.disable_double_pipe {YES} \
      CONFIG.en_gt_pclk {false} \
      CONFIG.enable_gtwizard {true} \
      CONFIG.enable_rpll {false} \
      CONFIG.ins_loss_profile {Add-in_Card} \
      CONFIG.lane_order {Bottom} \
      CONFIG.lane_reversal {false} \
      CONFIG.phy_async_en {true} \
      CONFIG.phy_coreclk_freq {500_MHz} \
      CONFIG.phy_refclk_freq {100_MHz} \
      CONFIG.phy_userclk2_freq {250_MHz} \
      CONFIG.phy_userclk_freq {250_MHz} \
      CONFIG.pipeline_stages {1} \
      CONFIG.tx_preset {4} \
   ] $pcie_phy
  } else {
    set_property -dict [list \
      CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {32.0_GT/s} \
      CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X4} \
      CONFIG.aspm {No_ASPM} \
      CONFIG.async_mode {SRNS} \
      CONFIG.disable_double_pipe {YES} \
      CONFIG.en_gt_pclk {false} \
      CONFIG.enable_gtwizard {true} \
      CONFIG.ins_loss_profile {Add-in_Card} \
      CONFIG.lane_order {Bottom} \
      CONFIG.lane_reversal {false} \
      CONFIG.phy_async_en {true} \
      CONFIG.phy_coreclk_freq {500_MHz} \
      CONFIG.phy_refclk_freq {100_MHz} \
      CONFIG.phy_userclk2_freq {250_MHz} \
      CONFIG.phy_userclk_freq {250_MHz} \
      CONFIG.pipeline_stages {4} \
      CONFIG.sim_model {NO} \
      CONFIG.tx_preset {4} \
    ] $pcie_phy
  }

  # Create instance: refclk_ibuf, and set properties
  set refclk_ibuf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf refclk_ibuf ]
  set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $refclk_ibuf


  # Create instance: gtwiz_versal_0, and set properties
  set gtwiz_versal_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gtwiz_versal:1.0 gtwiz_versal_0 ]
  if {$is_vck190 | $is_vmk180} {
    set_property -dict [list \
      CONFIG.GT_TYPE {GTY} \
      CONFIG.INTF0_GT_SETTINGS(GT_DIRECTION) {DUPLEX} \
      CONFIG.INTF0_GT_SETTINGS(GT_TYPE) {GTY} \
      CONFIG.INTF0_GT_SETTINGS(LR0_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
  CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 8B10B TX_LINE_RATE 2.5 TX_USER_DATA_WIDTH 16 TX_INT_DATA_WIDTH 20 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
  250 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
  1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
  LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE LPM RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 8B10B RX_LINE_RATE 2.5 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 16 RX_INT_DATA_WIDTH\
  20 RX_REFCLK_FREQUENCY 100} \
      CONFIG.INTF0_GT_SETTINGS(LR1_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
  CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 8B10B TX_LINE_RATE 5.0 TX_USER_DATA_WIDTH 16 TX_INT_DATA_WIDTH 20 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
  250 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
  1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
  LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE LPM RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 8B10B RX_LINE_RATE 5.0 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 16 RX_INT_DATA_WIDTH\
  20 RX_REFCLK_FREQUENCY 100} \
      CONFIG.INTF0_GT_SETTINGS(LR2_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
  CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 128B130B TX_LINE_RATE 8.0 TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH 32 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
  250 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
  1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
  LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE DFE RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 128B130B RX_LINE_RATE 8.0 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH\
  32 RX_REFCLK_FREQUENCY 100} \
      CONFIG.INTF0_GT_SETTINGS(LR3_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
  CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 128B130B TX_LINE_RATE 16.0 TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH 32 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
  250 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
  1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
  LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE DFE RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 128B130B RX_LINE_RATE 16.0 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH\
  32 RX_REFCLK_FREQUENCY 100} \
    CONFIG.INTF0_GT_SETTINGS(LR4_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 128B130B TX_LINE_RATE 16.0 TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH 32 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
250 TX_ACTUAL_REFCLK_FREQUENCY 100.0 TX_FRACN_ENABLED false TX_FRACN_NUMERATOR 0 TX_PIPM_ENABLE false TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A TX_BUFFER_RESET_ON_RATE_CHANGE\
ENABLE PRESET None INTERNAL_PRESET None OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 false RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE\
ENABLE RX_COMMA_ALIGN_WORD 1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false\
RX_JTOL_FC 1 RX_PLL_TYPE LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE DFE RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 128B130B RX_LINE_RATE 16.0 RX_PPM_OFFSET 0\
RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH 32 RX_REFCLK_FREQUENCY 100 RESET_SEQUENCE_INTERVAL 0 RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 322.265625 RX_64B66B_CRC false RX_64B66B_DECODER false RX_64B66B_DESCRAMBLER\
false RX_ACTUAL_REFCLK_FREQUENCY 100.0 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE\
ENABLE RX_CB_DISP 00000000 RX_CB_DISP_0_0 false RX_CB_DISP_0_1 false RX_CB_DISP_0_2 false RX_CB_DISP_0_3 false RX_CB_DISP_1_0 false RX_CB_DISP_1_1 false RX_CB_DISP_1_2 false RX_CB_DISP_1_3 false RX_CB_K\
00000000 RX_CB_K_0_0 false RX_CB_K_0_1 false RX_CB_K_0_2 false RX_CB_K_0_3 false RX_CB_K_1_0 false RX_CB_K_1_1 false RX_CB_K_1_2 false RX_CB_K_1_3 false RX_CB_LEN_SEQ 1 RX_CB_MASK 00000000 RX_CB_MASK_0_0\
false RX_CB_MASK_0_1 false RX_CB_MASK_0_2 false RX_CB_MASK_0_3 false RX_CB_MASK_1_0 false RX_CB_MASK_1_1 false RX_CB_MASK_1_2 false RX_CB_MASK_1_3 false RX_CB_MAX_LEVEL 1 RX_CB_MAX_SKEW 1 RX_CB_NUM_SEQ\
0 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CB_VAL_0_0 00000000 RX_CB_VAL_0_1 00000000 RX_CB_VAL_0_2 00000000 RX_CB_VAL_0_3 00000000 RX_CB_VAL_1_0 00000000\
RX_CB_VAL_1_1 00000000 RX_CB_VAL_1_2 00000000 RX_CB_VAL_1_3 00000000 RX_CC_DISP 00000000 RX_CC_DISP_0_0 false RX_CC_DISP_0_1 false RX_CC_DISP_0_2 false RX_CC_DISP_0_3 false RX_CC_DISP_1_0 false RX_CC_DISP_1_1\
false RX_CC_DISP_1_2 false RX_CC_DISP_1_3 false RX_CC_K 00000000 RX_CC_K_0_1 false RX_CC_K_0_2 false RX_CC_K_0_3 false RX_CC_K_1_0 false RX_CC_K_1_1 false RX_CC_K_1_2 false RX_CC_K_1_3 false RX_CC_MASK\
00000000 RX_CC_MASK_0_1 false RX_CC_MASK_0_2 false RX_CC_MASK_0_3 false RX_CC_MASK_1_0 false RX_CC_MASK_1_1 false RX_CC_MASK_1_2 false RX_CC_MASK_1_3 false RX_CC_PERIODICITY 5000 RX_CC_PRECEDENCE ENABLE\
RX_CC_REPEAT_WAIT 0 RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000011100 RX_CC_VAL_0_1 00000000 RX_CC_VAL_0_2 00000000 RX_CC_VAL_0_3 00000000 RX_CC_VAL_1_0 00000000\
RX_CC_VAL_1_1 00000000 RX_CC_VAL_1_2 00000000 RX_CC_VAL_1_3 00000000 RX_COMMA_SHOW_REALIGN_ENABLE true RX_COMMA_VALID_ONLY 0 RX_COUPLING AC RX_FRACN_ENABLED false RX_FRACN_NUMERATOR 0 RX_JTOL_LF_SLOPE\
-20 RX_RATE_GROUP A RX_TERMINATION PROGRAMMABLE RX_TERMINATION_PROG_VALUE 800} \
    CONFIG.INTF0_PARENTID {pl_pcie_qdma_rp_pcie_phy_0} \
    CONFIG.INTF0_PCIE_ENABLE {true} \
    CONFIG.INTF_PARENT_PIN_LIST {QUAD0_RX0 /qdma_0_support/pcie_phy/GT_RX0 QUAD0_RX1 /qdma_0_support/pcie_phy/GT_RX1 QUAD0_RX2 /qdma_0_support/pcie_phy/GT_RX2 QUAD0_RX3 /qdma_0_support/pcie_phy/GT_RX3\
QUAD0_TX0 /qdma_0_support/pcie_phy/GT_TX0 QUAD0_TX1 /qdma_0_support/pcie_phy/GT_TX1 QUAD0_TX2 /qdma_0_support/pcie_phy/GT_TX2 QUAD0_TX3 /qdma_0_support/pcie_phy/GT_TX3} \
    CONFIG.QUAD0_CH0_PCIERSTB_EN {true} \
    CONFIG.QUAD0_CH0_PHYREADY_EN {true} \
    CONFIG.QUAD0_CH0_PHYSTATUS_EN {true} \
    CONFIG.QUAD0_CH1_PCIERSTB_EN {true} \
    CONFIG.QUAD0_CH1_PHYREADY_EN {true} \
    CONFIG.QUAD0_CH1_PHYSTATUS_EN {true} \
    CONFIG.QUAD0_CH2_PCIERSTB_EN {true} \
    CONFIG.QUAD0_CH2_PHYREADY_EN {true} \
    CONFIG.QUAD0_CH2_PHYSTATUS_EN {true} \
    CONFIG.QUAD0_CH3_PCIERSTB_EN {true} \
    CONFIG.QUAD0_CH3_PHYREADY_EN {true} \
    CONFIG.QUAD0_CH3_PHYSTATUS_EN {true} \
    CONFIG.QUAD0_GT0_BUFGT_EN {true} \
    CONFIG.QUAD0_GT1_BUFGT_EN {true} \
    CONFIG.QUAD0_GT2_BUFGT_EN {true} \
    CONFIG.QUAD0_GT3_BUFGT_EN {true} \
    CONFIG.QUAD0_GT_RXMARGIN_INTF_EN {true} \
    CONFIG.QUAD0_PCIELTSSM_EN {true} \
    CONFIG.QUAD0_REFCLK_STRING {HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK0_RPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_RPLLGTREFCLK0\
refclk_PROT0_R0_100_MHz_unique1} \
    CONFIG.QUAD0_USAGE {TX_QUAD_CH {TXQuad_0_/pl_pcie_qdma_rp_gtwiz_versal_0_0/pl_pcie_qdma_rp_gtwiz_versal_0_0_gt_quad_base_0 {/pl_pcie_qdma_rp_gtwiz_versal_0_0/pl_pcie_qdma_rp_gtwiz_versal_0_0_gt_quad_base_0\
pl_pcie_qdma_rp_pcie_phy_0.IP_CH0,pl_pcie_qdma_rp_pcie_phy_0.IP_CH1,pl_pcie_qdma_rp_pcie_phy_0.IP_CH2,pl_pcie_qdma_rp_pcie_phy_0.IP_CH3 MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 1}} RX_QUAD_CH {RXQuad_0_/pl_pcie_qdma_rp_gtwiz_versal_0_0/pl_pcie_qdma_rp_gtwiz_versal_0_0_gt_quad_base_0\
{/pl_pcie_qdma_rp_gtwiz_versal_0_0/pl_pcie_qdma_rp_gtwiz_versal_0_0_gt_quad_base_0 pl_pcie_qdma_rp_pcie_phy_0.IP_CH0,pl_pcie_qdma_rp_pcie_phy_0.IP_CH1,pl_pcie_qdma_rp_pcie_phy_0.IP_CH2,pl_pcie_qdma_rp_pcie_phy_0.IP_CH3\
MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 1}}} \
    ] $gtwiz_versal_0

    set_property -dict [list \
      CONFIG.INTF0_PARENTID.VALUE_MODE {auto} \
      CONFIG.INTF_PARENT_PIN_LIST.VALUE_MODE {auto} \
      CONFIG.QUAD0_USAGE.VALUE_MODE {auto} \
    ] $gtwiz_versal_0
  } else {
    set_property -dict [list \
      CONFIG.GT_TYPE {GTYP} \
      CONFIG.INTF0_GT_SETTINGS(GT_DIRECTION) {DUPLEX} \
      CONFIG.INTF0_GT_SETTINGS(GT_TYPE) {GTYP} \
      CONFIG.INTF0_GT_SETTINGS(LR0_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
  CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 8B10B TX_LINE_RATE 2.5 TX_USER_DATA_WIDTH 16 TX_INT_DATA_WIDTH 20 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
  250 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
  1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
  LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE LPM RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 8B10B RX_LINE_RATE 2.5 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 16 RX_INT_DATA_WIDTH\
  20 RX_REFCLK_FREQUENCY 100} \
      CONFIG.INTF0_GT_SETTINGS(LR1_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
  CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 8B10B TX_LINE_RATE 5.0 TX_USER_DATA_WIDTH 16 TX_INT_DATA_WIDTH 20 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
  250 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
  1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
  LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE LPM RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 8B10B RX_LINE_RATE 5.0 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 16 RX_INT_DATA_WIDTH\
  20 RX_REFCLK_FREQUENCY 100} \
      CONFIG.INTF0_GT_SETTINGS(LR2_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
  CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 128B130B TX_LINE_RATE 8.0 TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH 32 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
  250 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
  1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
  LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE DFE RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 128B130B RX_LINE_RATE 8.0 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH\
  32 RX_REFCLK_FREQUENCY 100} \
      CONFIG.INTF0_GT_SETTINGS(LR3_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
  CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 128B130B TX_LINE_RATE 16.0 TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH 32 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
  250 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
  1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
  LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE DFE RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 128B130B RX_LINE_RATE 16.0 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH\
  32 RX_REFCLK_FREQUENCY 100} \
      CONFIG.INTF0_GT_SETTINGS(LR4_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
  CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 128B130B TX_LINE_RATE 32.0 TX_USER_DATA_WIDTH 64 TX_INT_DATA_WIDTH 64 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
  250 TX_ACTUAL_REFCLK_FREQUENCY 100.0 TX_FRACN_ENABLED false TX_FRACN_NUMERATOR 0 TX_PIPM_ENABLE false TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A TX_BUFFER_RESET_ON_RATE_CHANGE\
  ENABLE PRESET None INTERNAL_PRESET None OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 false RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE\
  ENABLE RX_COMMA_ALIGN_WORD 1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false\
  RX_JTOL_FC 1 RX_PLL_TYPE LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE DFE RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 128B130B RX_LINE_RATE 32.0 RX_PPM_OFFSET 0\
  RX_USER_DATA_WIDTH 64 RX_INT_DATA_WIDTH 64 RX_REFCLK_FREQUENCY 100 RESET_SEQUENCE_INTERVAL 0 RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 322.265625 RX_64B66B_CRC false RX_64B66B_DECODER false RX_64B66B_DESCRAMBLER\
  false RX_ACTUAL_REFCLK_FREQUENCY 100.0 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE\
  ENABLE RX_CB_DISP 00000000 RX_CB_DISP_0_0 false RX_CB_DISP_0_1 false RX_CB_DISP_0_2 false RX_CB_DISP_0_3 false RX_CB_DISP_1_0 false RX_CB_DISP_1_1 false RX_CB_DISP_1_2 false RX_CB_DISP_1_3 false RX_CB_K\
  00000000 RX_CB_K_0_0 false RX_CB_K_0_1 false RX_CB_K_0_2 false RX_CB_K_0_3 false RX_CB_K_1_0 false RX_CB_K_1_1 false RX_CB_K_1_2 false RX_CB_K_1_3 false RX_CB_LEN_SEQ 1 RX_CB_MASK 00000000 RX_CB_MASK_0_0\
  false RX_CB_MASK_0_1 false RX_CB_MASK_0_2 false RX_CB_MASK_0_3 false RX_CB_MASK_1_0 false RX_CB_MASK_1_1 false RX_CB_MASK_1_2 false RX_CB_MASK_1_3 false RX_CB_MAX_LEVEL 1 RX_CB_MAX_SKEW 1 RX_CB_NUM_SEQ\
  0 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CB_VAL_0_0 00000000 RX_CB_VAL_0_1 00000000 RX_CB_VAL_0_2 00000000 RX_CB_VAL_0_3 00000000 RX_CB_VAL_1_0 00000000\
  RX_CB_VAL_1_1 00000000 RX_CB_VAL_1_2 00000000 RX_CB_VAL_1_3 00000000 RX_CC_DISP 00000000 RX_CC_DISP_0_0 false RX_CC_DISP_0_1 false RX_CC_DISP_0_2 false RX_CC_DISP_0_3 false RX_CC_DISP_1_0 false RX_CC_DISP_1_1\
  false RX_CC_DISP_1_2 false RX_CC_DISP_1_3 false RX_CC_K 00000000 RX_CC_K_0_1 false RX_CC_K_0_2 false RX_CC_K_0_3 false RX_CC_K_1_0 false RX_CC_K_1_1 false RX_CC_K_1_2 false RX_CC_K_1_3 false RX_CC_MASK\
  00000000 RX_CC_MASK_0_1 false RX_CC_MASK_0_2 false RX_CC_MASK_0_3 false RX_CC_MASK_1_0 false RX_CC_MASK_1_1 false RX_CC_MASK_1_2 false RX_CC_MASK_1_3 false RX_CC_PERIODICITY 5000 RX_CC_PRECEDENCE ENABLE\
  RX_CC_REPEAT_WAIT 0 RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000011100 RX_CC_VAL_0_1 00000000 RX_CC_VAL_0_2 00000000 RX_CC_VAL_0_3 00000000 RX_CC_VAL_1_0 00000000\
  RX_CC_VAL_1_1 00000000 RX_CC_VAL_1_2 00000000 RX_CC_VAL_1_3 00000000 RX_COMMA_SHOW_REALIGN_ENABLE true RX_COMMA_VALID_ONLY 0 RX_COUPLING AC RX_FRACN_ENABLED false RX_FRACN_NUMERATOR 0 RX_JTOL_LF_SLOPE\
  -20 RX_RATE_GROUP A RX_TERMINATION PROGRAMMABLE RX_TERMINATION_PROG_VALUE 800} \
      CONFIG.INTF0_PARENTID {pl_pcie_qdma_rp_pcie_phy_0} \
      CONFIG.INTF0_PCIE_ENABLE {true} \
      CONFIG.INTF_PARENT_PIN_LIST {QUAD0_RX0 /qdma_0_support/pcie_phy/GT_RX0 QUAD0_RX1 /qdma_0_support/pcie_phy/GT_RX1 QUAD0_RX2 /qdma_0_support/pcie_phy/GT_RX2 QUAD0_RX3 /qdma_0_support/pcie_phy/GT_RX3\
  QUAD0_TX0 /qdma_0_support/pcie_phy/GT_TX0 QUAD0_TX1 /qdma_0_support/pcie_phy/GT_TX1 QUAD0_TX2 /qdma_0_support/pcie_phy/GT_TX2 QUAD0_TX3 /qdma_0_support/pcie_phy/GT_TX3} \
      CONFIG.QUAD0_CH0_PCIERSTB_EN {true} \
      CONFIG.QUAD0_CH0_PHYREADY_EN {true} \
      CONFIG.QUAD0_CH0_PHYSTATUS_EN {true} \
      CONFIG.QUAD0_CH1_PCIERSTB_EN {true} \
      CONFIG.QUAD0_CH1_PHYREADY_EN {true} \
      CONFIG.QUAD0_CH1_PHYSTATUS_EN {true} \
      CONFIG.QUAD0_CH2_PCIERSTB_EN {true} \
      CONFIG.QUAD0_CH2_PHYREADY_EN {true} \
      CONFIG.QUAD0_CH2_PHYSTATUS_EN {true} \
      CONFIG.QUAD0_CH3_PCIERSTB_EN {true} \
      CONFIG.QUAD0_CH3_PHYREADY_EN {true} \
      CONFIG.QUAD0_CH3_PHYSTATUS_EN {true} \
      CONFIG.QUAD0_GT0_BUFGT_EN {true} \
      CONFIG.QUAD0_GT1_BUFGT_EN {true} \
      CONFIG.QUAD0_GT2_BUFGT_EN {true} \
      CONFIG.QUAD0_GT3_BUFGT_EN {true} \
      CONFIG.QUAD0_GT_RXMARGIN_INTF_EN {true} \
      CONFIG.QUAD0_PCIELTSSM_EN {true} \
      CONFIG.QUAD0_REFCLK_STRING {HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK0_RPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_RPLLGTREFCLK0\
  refclk_PROT0_R0_100_MHz_unique1} \
      CONFIG.QUAD0_USAGE {TX_QUAD_CH {TXQuad_0_/pl_pcie_qdma_rp_gtwiz_versal_0_0/pl_pcie_qdma_rp_gtwiz_versal_0_0_gt_quad_base_0 {/pl_pcie_qdma_rp_gtwiz_versal_0_0/pl_pcie_qdma_rp_gtwiz_versal_0_0_gt_quad_base_0\
  pl_pcie_qdma_rp_pcie_phy_0.IP_CH0,pl_pcie_qdma_rp_pcie_phy_0.IP_CH1,pl_pcie_qdma_rp_pcie_phy_0.IP_CH2,pl_pcie_qdma_rp_pcie_phy_0.IP_CH3 MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 1}} RX_QUAD_CH {RXQuad_0_/pl_pcie_qdma_rp_gtwiz_versal_0_0/pl_pcie_qdma_rp_gtwiz_versal_0_0_gt_quad_base_0\
  {/pl_pcie_qdma_rp_gtwiz_versal_0_0/pl_pcie_qdma_rp_gtwiz_versal_0_0_gt_quad_base_0 pl_pcie_qdma_rp_pcie_phy_0.IP_CH0,pl_pcie_qdma_rp_pcie_phy_0.IP_CH1,pl_pcie_qdma_rp_pcie_phy_0.IP_CH2,pl_pcie_qdma_rp_pcie_phy_0.IP_CH3\
  MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 1}}} \
    ] $gtwiz_versal_0

    set_property -dict [list \
      CONFIG.INTF0_PARENTID.VALUE_MODE {auto} \
      CONFIG.INTF_PARENT_PIN_LIST.VALUE_MODE {auto} \
      CONFIG.QUAD0_USAGE.VALUE_MODE {auto} \
    ] $gtwiz_versal_0
  }

  # Create instance: ilconstant_1, and set properties
  set ilconstant_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant:1.0 ilconstant_1 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins refclk_ibuf/CLK_IN_D] [get_bd_intf_pins pcie_refclk]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins pcie_phy/pcie_mgt] [get_bd_intf_pins pcie_mgt]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins pcie/m_axis_cq] [get_bd_intf_pins m_axis_cq]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins pcie/m_axis_rc] [get_bd_intf_pins m_axis_rc]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins pcie/pcie_cfg_fc] [get_bd_intf_pins pcie_cfg_fc]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins pcie/pcie_cfg_interrupt] [get_bd_intf_pins pcie_cfg_interrupt]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins pcie/pcie_cfg_mesg_rcvd] [get_bd_intf_pins pcie_cfg_mesg_rcvd]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins pcie/pcie_cfg_mesg_tx] [get_bd_intf_pins pcie_cfg_mesg_tx]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins pcie/s_axis_cc] [get_bd_intf_pins s_axis_cc]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins pcie/s_axis_rq] [get_bd_intf_pins s_axis_rq]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins pcie/pcie_cfg_control] [get_bd_intf_pins pcie_cfg_control]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins pcie/pcie_cfg_mgmt] [get_bd_intf_pins pcie_cfg_mgmt]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins pcie/pcie_cfg_status] [get_bd_intf_pins pcie_cfg_status]
  connect_bd_intf_net -intf_net Conn14 [get_bd_intf_pins pcie/pcie_transmit_fc] [get_bd_intf_pins pcie_transmit_fc]
  connect_bd_intf_net -intf_net gt_quad_0_GT0_BUFGT [get_bd_intf_pins pcie_phy/GT_BUFGT] [get_bd_intf_pins gtwiz_versal_0/Quad0_GT0_BUFGT]
  connect_bd_intf_net -intf_net gt_quad_0_GT_Serial [get_bd_intf_pins pcie_phy/GT0_Serial] [get_bd_intf_pins gtwiz_versal_0/Quad0_GT_Serial]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX0 [get_bd_intf_pins pcie_phy/GT_RX0] [get_bd_intf_pins gtwiz_versal_0/INTF0_RX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX1 [get_bd_intf_pins pcie_phy/GT_RX1] [get_bd_intf_pins gtwiz_versal_0/INTF0_RX1_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX2 [get_bd_intf_pins pcie_phy/GT_RX2] [get_bd_intf_pins gtwiz_versal_0/INTF0_RX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX3 [get_bd_intf_pins pcie_phy/GT_RX3] [get_bd_intf_pins gtwiz_versal_0/INTF0_RX3_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX0 [get_bd_intf_pins pcie_phy/GT_TX0] [get_bd_intf_pins gtwiz_versal_0/INTF0_TX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX1 [get_bd_intf_pins pcie_phy/GT_TX1] [get_bd_intf_pins gtwiz_versal_0/INTF0_TX1_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX2 [get_bd_intf_pins pcie_phy/GT_TX2] [get_bd_intf_pins gtwiz_versal_0/INTF0_TX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX3 [get_bd_intf_pins pcie_phy/GT_TX3] [get_bd_intf_pins gtwiz_versal_0/INTF0_TX3_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_gt_rxmargin_q0 [get_bd_intf_pins pcie_phy/gt_rxmargin_q0] [get_bd_intf_pins gtwiz_versal_0/QUAD0_GT_RXMARGIN_INTF]
  connect_bd_intf_net -intf_net pcie_phy_mac_rx [get_bd_intf_pins pcie_phy/phy_mac_rx] [get_bd_intf_pins pcie/phy_mac_rx]
  connect_bd_intf_net -intf_net pcie_phy_mac_tx [get_bd_intf_pins pcie_phy/phy_mac_tx] [get_bd_intf_pins pcie/phy_mac_tx]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_command [get_bd_intf_pins pcie_phy/phy_mac_command] [get_bd_intf_pins pcie/phy_mac_command]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_rx_margining [get_bd_intf_pins pcie_phy/phy_mac_rx_margining] [get_bd_intf_pins pcie/phy_mac_rx_margining]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_status [get_bd_intf_pins pcie_phy/phy_mac_status] [get_bd_intf_pins pcie/phy_mac_status]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_tx_drive [get_bd_intf_pins pcie_phy/phy_mac_tx_drive] [get_bd_intf_pins pcie/phy_mac_tx_drive]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_tx_eq [get_bd_intf_pins pcie_phy/phy_mac_tx_eq] [get_bd_intf_pins pcie/phy_mac_tx_eq]

  # Create port connections
  connect_bd_net -net bufg_gt_sysclk_BUFG_GT_O  [get_bd_pins bufg_gt_sysclk/BUFG_GT_O] \
  [get_bd_pins gtwiz_versal_0/gtwiz_freerun_clk] \
  [get_bd_pins pcie/sys_clk] \
  [get_bd_pins pcie_phy/phy_refclk]
  connect_bd_net -net gt_quad_0_ch0_phyready  [get_bd_pins gtwiz_versal_0/QUAD0_ch0_phyready] \
  [get_bd_pins pcie_phy/ch0_phyready]
  connect_bd_net -net gt_quad_0_ch0_phystatus  [get_bd_pins gtwiz_versal_0/QUAD0_ch0_phystatus] \
  [get_bd_pins pcie_phy/ch0_phystatus]
  connect_bd_net -net gt_quad_0_ch0_rxoutclk  [get_bd_pins gtwiz_versal_0/QUAD0_RX0_outclk] \
  [get_bd_pins pcie_phy/gt_rxoutclk]
  connect_bd_net -net gt_quad_0_ch0_txoutclk  [get_bd_pins gtwiz_versal_0/QUAD0_TX0_outclk] \
  [get_bd_pins pcie_phy/gt_txoutclk]
  connect_bd_net -net gt_quad_0_ch1_phyready  [get_bd_pins gtwiz_versal_0/QUAD0_ch1_phyready] \
  [get_bd_pins pcie_phy/ch1_phyready]
  connect_bd_net -net gt_quad_0_ch1_phystatus  [get_bd_pins gtwiz_versal_0/QUAD0_ch1_phystatus] \
  [get_bd_pins pcie_phy/ch1_phystatus]
  connect_bd_net -net gt_quad_0_ch2_phyready  [get_bd_pins gtwiz_versal_0/QUAD0_ch2_phyready] \
  [get_bd_pins pcie_phy/ch2_phyready]
  connect_bd_net -net gt_quad_0_ch2_phystatus  [get_bd_pins gtwiz_versal_0/QUAD0_ch2_phystatus] \
  [get_bd_pins pcie_phy/ch2_phystatus]
  connect_bd_net -net gt_quad_0_ch3_phyready  [get_bd_pins gtwiz_versal_0/QUAD0_ch3_phyready] \
  [get_bd_pins pcie_phy/ch3_phyready]
  connect_bd_net -net gt_quad_0_ch3_phystatus  [get_bd_pins gtwiz_versal_0/QUAD0_ch3_phystatus] \
  [get_bd_pins pcie_phy/ch3_phystatus]
  connect_bd_net -net pcie_pcie_ltssm_state  [get_bd_pins pcie/pcie_ltssm_state] \
  [get_bd_pins pcie_ltssm_state] \
  [get_bd_pins pcie_phy/pcie_ltssm_state]
  connect_bd_net -net pcie_phy_gt_pcieltssm  [get_bd_pins pcie_phy/gt_pcieltssm] \
  [get_bd_pins gtwiz_versal_0/QUAD0_pcieltssm]
  connect_bd_net -net pcie_phy_gtrefclk  [get_bd_pins pcie_phy/gtrefclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_GTREFCLK0]
  connect_bd_net -net pcie_phy_pcierstb  [get_bd_pins pcie_phy/pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch0_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch1_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch2_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch3_pcierstb]
  connect_bd_net -net pcie_phy_phy_coreclk  [get_bd_pins pcie_phy/phy_coreclk] \
  [get_bd_pins pcie/phy_coreclk]
  connect_bd_net -net pcie_phy_phy_mcapclk  [get_bd_pins pcie_phy/phy_mcapclk] \
  [get_bd_pins pcie/phy_mcapclk]
  connect_bd_net -net pcie_phy_phy_pclk  [get_bd_pins pcie_phy/phy_pclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_TX0_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_TX1_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_TX2_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_TX3_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_RX0_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_RX1_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_RX2_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_RX3_usrclk] \
  [get_bd_pins pcie/phy_pclk]
  connect_bd_net -net pcie_phy_phy_userclk  [get_bd_pins pcie_phy/phy_userclk] \
  [get_bd_pins pcie/phy_userclk]
  connect_bd_net -net pcie_phy_phy_userclk2  [get_bd_pins pcie_phy/phy_userclk2] \
  [get_bd_pins pcie/phy_userclk2]
  connect_bd_net -net pcie_phy_rdy_out  [get_bd_pins pcie/phy_rdy_out] \
  [get_bd_pins phy_rdy_out]
  connect_bd_net -net pcie_user_clk  [get_bd_pins pcie/user_clk] \
  [get_bd_pins user_clk]
  connect_bd_net -net pcie_user_lnk_up  [get_bd_pins pcie/user_lnk_up] \
  [get_bd_pins user_lnk_up]
  connect_bd_net -net pcie_user_reset  [get_bd_pins pcie/user_reset] \
  [get_bd_pins user_reset]
  connect_bd_net -net refclk_ibuf_IBUF_DS_ODIV2  [get_bd_pins refclk_ibuf/IBUF_DS_ODIV2] \
  [get_bd_pins bufg_gt_sysclk/BUFG_GT_I]
  connect_bd_net -net refclk_ibuf_IBUF_OUT  [get_bd_pins refclk_ibuf/IBUF_OUT] \
  [get_bd_pins pcie/sys_clk_gt] \
  [get_bd_pins pcie_phy/phy_gtrefclk]
  connect_bd_net -net sys_reset_1  [get_bd_pins sys_reset] \
  [get_bd_pins pcie/sys_reset] \
  [get_bd_pins pcie_phy/phy_rst_n]
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins ilconstant_1/dout] \
  [get_bd_pins bufg_gt_sysclk/BUFG_GT_CE]

  # Restore current instance
  current_bd_instance /
}

proc create_qdma { index } {
  global is_vpk120
  global is_vpk180
  global is_vck190
  global is_vmk180
  global is_vek280
  global is_vhk158
  global pcie_blk_locn
  set qdma [ create_bd_cell -type ip -vlnv xilinx.com:ip:qdma qdma_$index ]
  if {$is_vck190 | $is_vmk180} {
    set_property -dict [ list \
      CONFIG.pcie_blk_locn [lindex $pcie_blk_locn $index] \
      CONFIG.axibar_notranslate {true} \
      CONFIG.axibar_num {2} \
      CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
      CONFIG.dma_reset_source_sel {Phy_Ready} \
      CONFIG.functional_mode {AXI_Bridge} \
      CONFIG.mode_selection {Advanced} \
      CONFIG.pf0_bar0_prefetchable_qdma {true} \
      CONFIG.pf0_bar0_scale_qdma {Terabytes} \
      CONFIG.pf0_bar0_size_qdma {16} \
      CONFIG.pl_link_cap_max_link_speed {16.0_GT/s} \
      CONFIG.pl_link_cap_max_link_width {X4} \
    ] $qdma
  } else {
    set_property -dict [ list \
      CONFIG.enable_gtwizard {false} \
      CONFIG.pcie_blk_locn [lindex $pcie_blk_locn $index] \
      CONFIG.axibar_notranslate {true} \
      CONFIG.axibar_num {2} \
      CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
      CONFIG.dma_reset_source_sel {Phy_Ready} \
      CONFIG.functional_mode {AXI_Bridge} \
      CONFIG.mode_selection {Advanced} \
      CONFIG.pf0_bar0_prefetchable_qdma {true} \
      CONFIG.pf0_bar0_scale_qdma {Terabytes} \
      CONFIG.pf0_bar0_size_qdma {16} \
      CONFIG.pl_link_cap_max_link_speed {32.0_GT/s} \
      CONFIG.pl_link_cap_max_link_width {X4} \
    ] $qdma
  }
}

create_qdma 0
create_qdma_support 0
if {$dual_design} {
  create_qdma 1
  create_qdma_support 1
}

# Constant high
create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant:1.0 const_high

# Ports
proc connect_qdma_ports { index } {
  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pci_exp_$index
  connect_bd_intf_net -intf_net qdma_support_${index}_pcie_mgt [get_bd_intf_ports pci_exp_$index] [get_bd_intf_pins qdma_support_${index}/pcie_mgt]

  create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk_$index
  connect_bd_intf_net -intf_net pcie_refclk_$index [get_bd_intf_ports ref_clk_$index] [get_bd_intf_pins qdma_support_${index}/pcie_refclk]
}

connect_qdma_ports 0
if {$dual_design} {
  connect_qdma_ports 1
}

# QDMA interrupts
proc connect_qdma_intr { index } {
  global intr_list
  lappend intr_list "qdma_$index/interrupt_out"
  lappend intr_list "qdma_$index/interrupt_out_msi_vec0to31"
  lappend intr_list "qdma_$index/interrupt_out_msi_vec32to63"
}

connect_qdma_intr 0
if {$dual_design} {
  connect_qdma_intr 1
}

# Connections between QDMA and QDMA support block
proc connect_qdma_support { index } {

  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/m_axis_cq] [get_bd_intf_pins qdma_${index}/m_axis_cq]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/m_axis_rc] [get_bd_intf_pins qdma_${index}/m_axis_rc]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_fc] [get_bd_intf_pins qdma_${index}/pcie_cfg_fc]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_mesg_rcvd] [get_bd_intf_pins qdma_${index}/pcie_cfg_mesg_rcvd]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_mesg_tx] [get_bd_intf_pins qdma_${index}/pcie_cfg_mesg_tx]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_status] [get_bd_intf_pins qdma_${index}/pcie_cfg_status_if]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_transmit_fc] [get_bd_intf_pins qdma_${index}/pcie_transmit_fc_if]
  connect_bd_net [get_bd_pins qdma_support_${index}/phy_rdy_out] [get_bd_pins qdma_${index}/phy_rdy_out_sd]
  connect_bd_net [get_bd_pins qdma_support_${index}/user_clk] [get_bd_pins qdma_${index}/user_clk_sd]
  connect_bd_net [get_bd_pins qdma_support_${index}/user_lnk_up] [get_bd_pins qdma_${index}/user_lnk_up_sd]
  connect_bd_net [get_bd_pins qdma_support_${index}/user_reset] [get_bd_pins qdma_${index}/user_reset_sd]
  connect_bd_intf_net [get_bd_intf_pins qdma_${index}/pcie_cfg_control_if] -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_control]
  connect_bd_intf_net [get_bd_intf_pins qdma_${index}/pcie_cfg_interrupt] -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_interrupt]
  connect_bd_intf_net [get_bd_intf_pins qdma_${index}/pcie_cfg_mgmt_if] -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_mgmt]
  connect_bd_intf_net [get_bd_intf_pins qdma_${index}/s_axis_cc] -boundary_type upper [get_bd_intf_pins qdma_support_${index}/s_axis_cc]
  connect_bd_intf_net [get_bd_intf_pins qdma_${index}/s_axis_rq] -boundary_type upper [get_bd_intf_pins qdma_support_${index}/s_axis_rq]
  connect_bd_net [get_bd_pins const_high/dout] [get_bd_pins qdma_support_${index}/sys_reset]
  connect_bd_net [get_bd_pins const_high/dout] [get_bd_pins qdma_${index}/soft_reset_n]

}

connect_qdma_support 0
if {$dual_design} {
  connect_qdma_support 1
}

# QDMA axi_aclk drives CIPS M_AXI_FPD/LPD clock inputs and the NoC
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins versal_cips_0/m_axi_fpd_aclk]
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins versal_cips_0/m_axi_lpd_aclk]
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins axi_noc_0/aclk9]

# Add processor system reset for CIPS pl0_resetn
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset_pl0
connect_bd_net [get_bd_pins versal_cips_0/pl0_resetn] [get_bd_pins reset_pl0/ext_reset_in]
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins reset_pl0/slowest_sync_clk]

# Add smartconnect for the M_AXI_BRIDGE of the QDMA
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smc_m_axi_bridge
if {$dual_design} {
  set_property -dict [list CONFIG.NUM_CLKS {3} CONFIG.NUM_MI {1} CONFIG.NUM_SI {2}] [get_bd_cells smc_m_axi_bridge]
  connect_bd_intf_net [get_bd_intf_pins smc_m_axi_bridge/M00_AXI] [get_bd_intf_pins axi_noc_0/S08_AXI]
  connect_bd_intf_net [get_bd_intf_pins qdma_0/M_AXI_BRIDGE] [get_bd_intf_pins smc_m_axi_bridge/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins qdma_1/M_AXI_BRIDGE] [get_bd_intf_pins smc_m_axi_bridge/S01_AXI]
  connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins smc_m_axi_bridge/aclk]
  connect_bd_net [get_bd_pins qdma_0/axi_aclk] [get_bd_pins smc_m_axi_bridge/aclk1]
  connect_bd_net [get_bd_pins qdma_1/axi_aclk] [get_bd_pins smc_m_axi_bridge/aclk2]
  connect_bd_net [get_bd_pins reset_pl0/peripheral_aresetn] [get_bd_pins smc_m_axi_bridge/aresetn]
} else {
  set_property -dict [list CONFIG.NUM_CLKS {2} CONFIG.NUM_MI {1} CONFIG.NUM_SI {1}] [get_bd_cells smc_m_axi_bridge]
  connect_bd_intf_net [get_bd_intf_pins smc_m_axi_bridge/M00_AXI] [get_bd_intf_pins axi_noc_0/S08_AXI]
  connect_bd_intf_net [get_bd_intf_pins qdma_0/M_AXI_BRIDGE] [get_bd_intf_pins smc_m_axi_bridge/S00_AXI]
  connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins smc_m_axi_bridge/aclk]
  connect_bd_net [get_bd_pins qdma_0/axi_aclk] [get_bd_pins smc_m_axi_bridge/aclk1]
  connect_bd_net [get_bd_pins reset_pl0/peripheral_aresetn] [get_bd_pins smc_m_axi_bridge/aresetn]
}

# Add smartconnects for the M_AXI_FPD to QDMA S_AXI_BRIDGE
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smc_m_axi_fpd
if {$dual_design} {
  set_property -dict [list CONFIG.NUM_CLKS {3} CONFIG.NUM_MI {2} CONFIG.NUM_SI {1}] [get_bd_cells smc_m_axi_fpd]
  connect_bd_intf_net [get_bd_intf_pins versal_cips_0/M_AXI_FPD] [get_bd_intf_pins smc_m_axi_fpd/S00_AXI]
  connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins smc_m_axi_fpd/aclk]
  connect_bd_net [get_bd_pins qdma_0/axi_aclk] [get_bd_pins smc_m_axi_fpd/aclk1]
  connect_bd_net [get_bd_pins qdma_1/axi_aclk] [get_bd_pins smc_m_axi_fpd/aclk2]
  connect_bd_intf_net [get_bd_intf_pins smc_m_axi_fpd/M00_AXI] [get_bd_intf_pins qdma_0/S_AXI_BRIDGE]
  connect_bd_intf_net [get_bd_intf_pins smc_m_axi_fpd/M01_AXI] [get_bd_intf_pins qdma_1/S_AXI_BRIDGE]
  connect_bd_net [get_bd_pins reset_pl0/peripheral_aresetn] [get_bd_pins smc_m_axi_fpd/aresetn]
} else {
  set_property -dict [list CONFIG.NUM_CLKS {2} CONFIG.NUM_MI {1} CONFIG.NUM_SI {1}] [get_bd_cells smc_m_axi_fpd]
  connect_bd_intf_net [get_bd_intf_pins versal_cips_0/M_AXI_FPD] [get_bd_intf_pins smc_m_axi_fpd/S00_AXI]
  connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins smc_m_axi_fpd/aclk]
  connect_bd_net [get_bd_pins qdma_0/axi_aclk] [get_bd_pins smc_m_axi_fpd/aclk1]
  connect_bd_intf_net [get_bd_intf_pins smc_m_axi_fpd/M00_AXI] [get_bd_intf_pins qdma_0/S_AXI_BRIDGE]
  connect_bd_net [get_bd_pins reset_pl0/peripheral_aresetn] [get_bd_pins smc_m_axi_fpd/aresetn]
}

# Add smartconnects for the M_AXI_LPD to QDMA S_AXI_LITE and S_AXI_LITE_CSR
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smc_m_axi_lpd
if {$dual_design} {
  set_property -dict [list CONFIG.NUM_CLKS {3} CONFIG.NUM_MI {4} CONFIG.NUM_SI {1}] [get_bd_cells smc_m_axi_lpd]
  connect_bd_intf_net [get_bd_intf_pins versal_cips_0/M_AXI_LPD] [get_bd_intf_pins smc_m_axi_lpd/S00_AXI]
  connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins smc_m_axi_lpd/aclk]
  connect_bd_net [get_bd_pins qdma_0/axi_aclk] [get_bd_pins smc_m_axi_lpd/aclk1]
  connect_bd_net [get_bd_pins qdma_1/axi_aclk] [get_bd_pins smc_m_axi_lpd/aclk2]
  connect_bd_intf_net [get_bd_intf_pins smc_m_axi_lpd/M00_AXI] [get_bd_intf_pins qdma_0/S_AXI_LITE]
  connect_bd_intf_net [get_bd_intf_pins smc_m_axi_lpd/M01_AXI] [get_bd_intf_pins qdma_0/S_AXI_LITE_CSR]
  connect_bd_intf_net [get_bd_intf_pins smc_m_axi_lpd/M02_AXI] [get_bd_intf_pins qdma_1/S_AXI_LITE]
  connect_bd_intf_net [get_bd_intf_pins smc_m_axi_lpd/M03_AXI] [get_bd_intf_pins qdma_1/S_AXI_LITE_CSR]
  connect_bd_net [get_bd_pins reset_pl0/peripheral_aresetn] [get_bd_pins smc_m_axi_lpd/aresetn]
} else {
  set_property -dict [list CONFIG.NUM_CLKS {2} CONFIG.NUM_MI {2} CONFIG.NUM_SI {1}] [get_bd_cells smc_m_axi_lpd]
  connect_bd_intf_net [get_bd_intf_pins versal_cips_0/M_AXI_LPD] [get_bd_intf_pins smc_m_axi_lpd/S00_AXI]
  connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins smc_m_axi_lpd/aclk]
  connect_bd_net [get_bd_pins qdma_0/axi_aclk] [get_bd_pins smc_m_axi_lpd/aclk1]
  connect_bd_intf_net [get_bd_intf_pins smc_m_axi_lpd/M00_AXI] [get_bd_intf_pins qdma_0/S_AXI_LITE]
  connect_bd_intf_net [get_bd_intf_pins smc_m_axi_lpd/M01_AXI] [get_bd_intf_pins qdma_0/S_AXI_LITE_CSR]
  connect_bd_net [get_bd_pins reset_pl0/peripheral_aresetn] [get_bd_pins smc_m_axi_lpd/aresetn]
}

# Assign any addresses
assign_bd_address

# Set BAR0 and BAR1 sizes
if {$dual_design} {
  set_property offset 0x480000000 [get_bd_addr_segs {versal_cips_0/M_AXI_FPD/SEG_qdma_0_BAR1}]
  set_property range 1G [get_bd_addr_segs {versal_cips_0/M_AXI_FPD/SEG_qdma_0_BAR1}]
  set_property offset 0x4c0000000 [get_bd_addr_segs {versal_cips_0/M_AXI_FPD/SEG_qdma_1_BAR1}]
  set_property range 1G [get_bd_addr_segs {versal_cips_0/M_AXI_FPD/SEG_qdma_1_BAR1}]
  set_property offset 0xA8000000 [get_bd_addr_segs {versal_cips_0/M_AXI_FPD/SEG_qdma_0_BAR0}]
  set_property range 64M [get_bd_addr_segs {versal_cips_0/M_AXI_FPD/SEG_qdma_0_BAR0}]
  set_property offset 0xAc000000 [get_bd_addr_segs {versal_cips_0/M_AXI_FPD/SEG_qdma_1_BAR0}]
  set_property range 64M [get_bd_addr_segs {versal_cips_0/M_AXI_FPD/SEG_qdma_1_BAR0}]
} else {
  set_property offset 0x480000000 [get_bd_addr_segs {versal_cips_0/M_AXI_FPD/SEG_qdma_0_BAR1}]
  set_property range 1G [get_bd_addr_segs {versal_cips_0/M_AXI_FPD/SEG_qdma_0_BAR1}]
  set_property offset 0xA8000000 [get_bd_addr_segs {versal_cips_0/M_AXI_FPD/SEG_qdma_0_BAR0}]
  set_property range 128M [get_bd_addr_segs {versal_cips_0/M_AXI_FPD/SEG_qdma_0_BAR0}]
}

# Include in address space to follow the CED
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_iou_slcr_0]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_1]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_2]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_3]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_4]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_5]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_6]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_7]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_8]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_9]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_10]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_11]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_12]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_13]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_14]
include_bd_addr_seg [get_bd_addr_segs -excluded versal_cips_0/PMC_NOC_AXI_0/SEG_versal_cips_0_pspmc_0_psv_pmc_cfi_cframe_bcast]

# Create PERST ports
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_low
set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells const_low]
create_bd_port -dir O -from 0 -to 0 -type rst perst_0
connect_bd_net [get_bd_pins /const_low/dout] [get_bd_ports perst_0]
if {$dual_design} {
  create_bd_port -dir O -from 0 -to 0 -type rst perst_1
  connect_bd_net [get_bd_pins /const_low/dout] [get_bd_ports perst_1]
}

# Constant to enable/disable 3.3V power supply of SSD2 and clock source
set const_dis_ssd2_pwr [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_dis_ssd2_pwr ]
create_bd_port -dir O disable_ssd2_pwr
connect_bd_net [get_bd_pins const_dis_ssd2_pwr/dout] [get_bd_ports disable_ssd2_pwr]
if {$dual_design} {
  # LOW to enable SSD2
  set_property -dict [list CONFIG.CONST_VAL {0}] $const_dis_ssd2_pwr
} else {
  # HIGH to disable SSD2
  set_property -dict [list CONFIG.CONST_VAL {1}] $const_dis_ssd2_pwr
}

# Connect the interrupts
set intr_index 0
foreach intr $intr_list {
  connect_bd_net [get_bd_pins $intr] [get_bd_pins versal_cips_0/pl_ps_irq$intr_index]
  set intr_index [expr {$intr_index+1}]
}

validate_bd_design
save_bd_design
