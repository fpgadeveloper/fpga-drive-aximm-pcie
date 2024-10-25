# -------------------------------------------------------------------------------------
# Opsero Electronic Design Inc. Copyright 2024
# -------------------------------------------------------------------------------------

# Description
# -----------
# This Tcl script will create Vitis workspace and add a software application for the specified
# target design. If a target design is not specified, the user will be shown a list of target
# designs and asked to make a selection.

# Load functions from the workspace script
source tcl/workspace.tcl

# ----------------------------------------------------------------------------------------------
# Custom parameters
# ----------------------------------------------------------------------------------------------
# The following variables specify how the application should be created (from what 
# template if any), how things should be named and the dictionary of target designs.

# Set the Vivado directory containing the Vivado projects
set vivado_dir_rel "../Vivado"
set d_abs [file join [pwd] $vivado_dir_rel]
set vivado_dir [file normalize $d_abs]

# Set the application name
set app_name "ssd_test"

# Specify the postfix on the Vivado projects (if one is used)
set vivado_postfix ""

# Set the app template used to create the application
set support_app "empty_application"
set template_app "Empty Application"

# Microblaze designs: Generate combined .bit and .elf file
set mb_combine_bit_elf 1

# Possible targets (board name in lower case for the board.h file)
# UPDATER START
dict set target_dict auboard { auboard_15p }
dict set target_dict kc705_hpc { kc705 }
dict set target_dict kc705_lpc { kc705 }
dict set target_dict kcu105_hpc { kcu105 }
dict set target_dict kcu105_lpc { kcu105 }
dict set target_dict pz_7015 { picozed_7015_fmc2 }
dict set target_dict pz_7030 { picozed_7030_fmc2 }
dict set target_dict uzev { ultrazed_7ev_cc }
dict set target_dict vc707_hpc1 { vc707 }
dict set target_dict vc707_hpc2 { vc707 }
dict set target_dict vc709_hpc { vc709 }
dict set target_dict vck190_fmcp1 { vck190 }
dict set target_dict vck190_fmcp2 { vck190 }
dict set target_dict vhk158 { vhk158 }
dict set target_dict vmk180_fmcp1 { vmk180 }
dict set target_dict vmk180_fmcp2 { vmk180 }
dict set target_dict vek280 { vek280 }
dict set target_dict vek280_es_revb { vek280_es_revb }
dict set target_dict vpk120 { vpk120 }
dict set target_dict vpk180 { vpk180 }
dict set target_dict vcu118 { vcu118 }
dict set target_dict zc706_hpc { zc706 }
dict set target_dict zc706_lpc { zc706 }
dict set target_dict zcu104 { zcu104 }
dict set target_dict zcu106_hpc0 { zcu106 }
dict set target_dict zcu106_hpc1 { zcu106 }
dict set target_dict zcu111 { zcu111 }
dict set target_dict zcu208 { zcu208 }
dict set target_dict zcu216 { zcu216 }
# UPDATER END

# ----------------------------------------------------------------------------------------------
# Custom modifications functions
# ----------------------------------------------------------------------------------------------
# These functions make custom changes to the platform or standard application template 
# such as modifying files or copying sources into the platform/application.
# These functions are called after creating the platform/application and before build.

# Modifies the linker script such that all sections are relocated to local mem.
# This allows us to store the test application in the bitstream and provide a boot
# file for all the Microblaze designs.
proc linker_script_to_local_mem {linker_filename} {
  set fd [open "${linker_filename}" "r"]
  set file_data [read $fd]
  close $fd

  set local_mem ""
  set mig_mem ""
  
  # Find the local memory name
  set data [split $file_data "\n"]
  foreach line $data {
    if {[str_contains $line "local_memory"]} {
      set words [regexp -all -inline {\S+} $line]
      set local_mem [lindex $words 0]
      break
    }
  }
  
  # Find the MIG memory name
  foreach line $data {
    if {[str_contains $line "ORIGIN"]} {
      if {[str_contains $line "mig"] || [str_contains $line "ddr"]} {
        set words [regexp -all -inline {\S+} $line]
        set mig_mem [lindex $words 0]
        break
      }
    }
  }

  # Write to new linker script and replace MIG references with local mem
  set new_filename "${linker_filename}.txt"
  set fd [open "$new_filename" "w"]
  foreach line $data {
    if {[str_contains $line ">"]} {
      puts $fd [string map "$mig_mem $local_mem" $line]
    } else {
      puts $fd $line
    }
  }
  close $fd

  # Delete the old linker script
  file delete $linker_filename
  
  # Rename new linker script to the old filename
  file rename $new_filename $linker_filename
  
  return 0
}

# Modifies the linker script such that all sections are relocated to DDR mem.
# This is needed for the Zynq designs because the Linker script generator tries
# to assign all sections to BAR0 instead of the DDR, resulting in failure of
# the application to run.
proc linker_script_to_ddr_mem {linker_filename} {
  set fd [open "$linker_filename" "r"]
  set file_data [read $fd]
  close $fd
  
  set ddr_mem ""
  
  # Find the DDR memory name
  set data [split $file_data "\n"]
  foreach line $data {
    if {[str_contains $line "ps7_ddr"]} {
      set words [regexp -all -inline {\S+} $line]
      set ddr_mem [lindex $words 0]
      break
    }
  }
  
  # Write to new linker script and assign all sections to DDR mem
  set new_filename "$linker_filename.txt"
  set fd [open "$new_filename" "w"]
  foreach line $data {
    if {[str_contains $line ">"]} {
      puts $fd "\} > $ddr_mem"
    } else {
      puts $fd $line
    }
  }
  close $fd
  
  # Delete the old linker script
  file delete $linker_filename
  
  file rename $new_filename $linker_filename
  
  return 0
}

proc custom_platform_mods {platform_name} {
  # No platform mods required
}

proc custom_app_mods {platform_name app_name workspace_dir} {
  set proc_instance [get_processor_from_platform $platform_name]
  # If the hardware contains the XDMA (all Zynq MP designs and VCU118 designs)
  if {[str_contains $proc_instance "psu_cortex"] || [str_contains $platform_name "vcu118"]} {
    # Copy the XDMA application from common/src
    file copy "common/src/xdmapcie_rc_enumerate_example.c" ${workspace_dir}/${app_name}/src
  } elseif {[str_contains $proc_instance "psv_cortexa72_"]} {
    # Copy the XDMA application from common/src
    file copy "common/src/xdmapcie_rc_enumerate_example.c" ${workspace_dir}/${app_name}/src
  } else {
    # Copy the AXI PCIe application from common/src
    file copy "common/src/pcie_enumerate.c" ${workspace_dir}/${app_name}/src
  }
  # For Microblaze designs, modify the linker script to put
  # all sections in local mem
  # For Zynq designs, modify linker script to put all sections in DDR
  if {[str_contains $proc_instance "microblaze"]} {
    linker_script_to_local_mem ${workspace_dir}/${app_name}/src/lscript.ld
  } elseif {[str_contains $proc_instance "ps7_cortex"]} {
    linker_script_to_ddr_mem ${workspace_dir}/${app_name}/src/lscript.ld
  }
}

# ----------------------------------------------------------------------------------------------
# End of custom sections
# ----------------------------------------------------------------------------------------------

# Target can be specified by creating the target variable before sourcing, or in the command line arguments
if { [info exists target] } {
  if { ![dict exists $target_dict $target] } {
    puts "Invalid target specified: $target"
    exit 1
  }
} elseif { $argc == 0 } {
  set target [select_target $target_dict]
} else {
  set target [lindex $argv 0]
  if { ![dict exists $target_dict $target] } {
    puts "Invalid target specified: $target"
    exit 1
  }
}

# At this point of the script, we are guaranteed to have a valid target
# The Vitis workspace directory name
set current_dir [pwd]
set workspace_dir [file join $current_dir "${target}_workspace"]

# Create the Vitis workspace
puts "Creating the Vitis workspace: $workspace_dir"
create_vitis_ws $workspace_dir $target $target_dict $vivado_dir $app_name $support_app $template_app


