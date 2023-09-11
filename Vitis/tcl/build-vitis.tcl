#!/usr/bin/tclsh

# Description
# -----------
# This Tcl script will create Vitis workspace with software applications for each of the
# exported hardware designs in the ../Vivado directory.

# Set the Vivado directories containing the Vivado projects
set vivado_dirs_rel [list "../Vivado"]
set vivado_dirs {}
foreach d $vivado_dirs_rel {
  set d_abs [file join [pwd] $d]
  append vivado_dirs [file normalize $d_abs] " "
}

# Set the application postfix
# Applications will be named using the app_postfix appended to the board name
set app_postfix "_ssd_test"

# Specify the postfix on the Vivado projects (if one is used)
set vivado_postfix ""

# Set the app template used to create the application
set support_app "empty_application"
set template_app "Empty Application"

# Microblaze designs: Generate combined .bit and .elf file
set mb_combine_bit_elf 1

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

# ----------------------------------------------------------------------------------------------
# Custom modifications functions
# ----------------------------------------------------------------------------------------------
# Use these functions to make custom changes to the platform or standard application template 
# such as modifying files or copying sources into the platform/application.
# These functions are called after creating the platform/application and before build.

proc custom_platform_mods {platform_name} {
  # No platform mods required
}

proc custom_app_mods {platform_name app_name} {
  set proc_instance [get_processor_from_platform $platform_name]
  # If the hardware contains the XDMA (all Zynq MP designs and VCU118 designs)
  if {[str_contains $proc_instance "psu_cortex"] || [str_contains $platform_name "vcu118"]} {
    # Copy the XDMA application from common/src
    file copy "common/src/xdmapcie_rc_enumerate_example.c" ${app_name}/src
  } else {
    # Copy the AXI PCIe application from common/src
    file copy "common/src/pcie_enumerate.c" ${app_name}/src
  }
  # For Microblaze designs, modify the linker script to put
  # all sections in local mem
  # For Zynq designs, modify linker script to put all sections in DDR
  if {[str_contains $proc_instance "microblaze"]} {
    linker_script_to_local_mem ${app_name}/src/lscript.ld
  } elseif {[str_contains $proc_instance "ps7_cortex"]} {
    linker_script_to_ddr_mem ${app_name}/src/lscript.ld
  }
}

# Call the workspace builder script
source tcl/workspace.tcl

