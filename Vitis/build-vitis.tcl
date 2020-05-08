#!/usr/bin/tclsh

# Description
# -----------
# This Tcl script will create Vitis workspace with software applications for each of the
# exported hardware designs in the ../Vivado directory.

# axipcie Driver modifications
# ----------------------------
# Some of the Vivado designs in this project use the AXI Memory Mapped to PCIe Gen2 IP
# and others use the AXI Bridge for PCIe Gen3 IP. Vitis comes with a driver for the Gen2
# core that is called "axipcie". The BSPs for projects using the Gen2 core refer to that 
# driver. You can find the driver sources in the Vitis installation files:
#
# C:\Xilinx\Vitis\<version>\data\embeddedsw\XilinxProcessorIPLib\drivers\axipcie_v3_1
#
# The Vitis does not currently supply a driver for the Gen3 core. However, there are enough
# similarities between the Gen2 and Gen3 cores that we can get away with using a modified 
# version of the "axipcie" driver, for doing some simple things such as link-up detection,
# determining link speed and width, and enumerating PCIe devices with the Gen3 core.
# 
# We create this "Gen3 version" of the driver by making a local copy of the "axipcie" driver
# sources and modifying the ".mdd" file, specifying that the driver supports the Gen3 core.
# For Vitis to be aware of our locally copied driver, we set Vitis's "repo" path to the path 
# of the driver. This script handles the copying and modification of the "axipcie" driver, 
# which is stored locally in the "EmbeddedSw/XilinxProcessorIPLib/drivers" directory.

# Set the Vivado directory containing the Vivado projects
set vivado_dir "../Vivado"
# Set the application postfix
set app_postfix "_ssd_test"

# Returns true if str contains substr
proc str_contains {str substr} {
  if {[string first $substr $str] == -1} {
    return 0
  } else {
    return 1
  }
}

# Recursive copy function
# Note: Does not overwrite existing files, thus our modified files are untouched.
proc copy-r {{dir .} target_dir} {
  foreach i [lsort [glob -nocomplain -dir $dir *]] {
    # Get the name of the file or directory
    set name [lindex [split $i /] end]
    if {[file type $i] eq {directory}} {
      # If doesn't exist in target, then create it
      set target_subdir ${target_dir}/$name
      if {[file exists $target_subdir] == 0} {
        file mkdir $target_subdir
      }
      # Copy all files contained in this subdirectory
      eval [copy-r $i $target_subdir]
    } else {
      # Copy the file if it doesn't already exist
      if {[file exists ${target_dir}/$name] == 0} {
        file copy $i $target_dir
      }
    }
  }
} ;# RS

# Fill in the local libraries with original sources without overwriting existing code
proc fill_local_libraries {} {
  # Xilinx Vitis install directory
  set vitis_dir $::env(XILINX_VITIS)
  # For each of the custom driver versions in our local repo
  foreach drv_dir [glob -type d "../EmbeddedSw/XilinxProcessorIPLib/drivers/*"] {
    # Work out the original version library directory name by removing the appended "9"
    set lib_name [string trimright [lindex [split $drv_dir /] end] "9"]
    set orig_dir "$vitis_dir/data/embeddedsw/XilinxProcessorIPLib/drivers/$lib_name"
    puts "Copying files from $orig_dir to $drv_dir"
    # Copy the original files to local repo, without overwriting existing code
    copy-r $orig_dir $drv_dir
  }
}

# Get the first processor name from a hardware design
# We use the "getperipherals" command to get the name of the processor that
# in the design. Below is an example of the output of "getperipherals":
# ================================================================================
# 
#               IP INSTANCE   VERSION                   TYPE           IP TYPE
# ================================================================================
# 
#            axi_ethernet_0       7.0           axi_ethernet        PERIPHERAL
#       axi_ethernet_0_fifo       4.1          axi_fifo_mm_s        PERIPHERAL
#           gmii_to_rgmii_0       4.0          gmii_to_rgmii        PERIPHERAL
#      processing_system7_0       5.5     processing_system7
#          ps7_0_axi_periph       2.1       axi_interconnect               BUS
#              ref_clk_fsel       1.1             xlconstant        PERIPHERAL
#                ref_clk_oe       1.1             xlconstant        PERIPHERAL
#                 ps7_pmu_0    1.00.a                ps7_pmu        PERIPHERAL
#                ps7_qspi_0    1.00.a               ps7_qspi        PERIPHERAL
#         ps7_qspi_linear_0    1.00.a        ps7_qspi_linear      MEMORY_CNTLR
#    ps7_axi_interconnect_0    1.00.a   ps7_axi_interconnect               BUS
#            ps7_cortexa9_0       5.2           ps7_cortexa9         PROCESSOR
#            ps7_cortexa9_1       5.2           ps7_cortexa9         PROCESSOR
#                 ps7_ddr_0    1.00.a                ps7_ddr      MEMORY_CNTLR
#            ps7_ethernet_0    1.00.a           ps7_ethernet        PERIPHERAL
#            ps7_ethernet_1    1.00.a           ps7_ethernet        PERIPHERAL
#                 ps7_usb_0    1.00.a                ps7_usb        PERIPHERAL
#                  ps7_sd_0    1.00.a               ps7_sdio        PERIPHERAL
#                  ps7_sd_1    1.00.a               ps7_sdio        PERIPHERAL
proc get_processor_name {hw_project_name} {
  set periphs [getperipherals $hw_project_name]
  # For each line of the peripherals table
  foreach line [split $periphs "\n"] {
    set values [regexp -all -inline {\S+} $line]
    # If the last column is "PROCESSOR", then get the "IP INSTANCE" name (1st col)
    if {[lindex $values end] == "PROCESSOR"} {
      return [lindex $values 0]
    }
  }
  return ""
}

proc design_contains_ip {hw_project_name ip_type} {
  set periphs [getperipherals $hw_project_name]
  # For each line of the peripherals table
  foreach line [split $periphs "\n"] {
    set values [regexp -all -inline {\S+} $line]
    # If we find the IP type in this design, then return 1
    if {[lindex $values 2] == $ip_type} {
      return 1
    }
  }
  return 0
}

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

# Returns list of Vivado projects in the given directory
proc get_vivado_projects {vivado_dir} {
  # Create the empty list
  set vivado_proj_list {}
  # Make a list of all subdirectories in Vivado directory
  foreach {vivado_proj_dir} [glob -type d "${vivado_dir}/*"] {
    # Get the vivado project name from the project directory name
    set vivado_proj [lindex [split $vivado_proj_dir /] end]
    # Ignore directories returned by glob that don't contain an underscore
    if { ([string first "_" $vivado_proj] == -1) } {
      continue
    }
    # Add the Vivado project to the list
    lappend vivado_proj_list $vivado_proj
  }
  return $vivado_proj_list
}

# Creates Vitis workspace for a project
proc create_vitis_ws {} {
  global vivado_dir
  global app_postfix
  # First make sure there is at least one exported Vivado project
  set exported_projects 0
  # Get list of Vivado projects
  set vivado_proj_list [get_vivado_projects $vivado_dir]
  # Check each Vivado project for export files
  foreach {vivado_folder} $vivado_proj_list {
    # If the hardware has been exported for Vitis
    if {[file exists "$vivado_dir/$vivado_folder/${vivado_folder}_wrapper.xsa"] == 1} {
      set exported_projects [expr {$exported_projects+1}]
    }
  }
  
  # If no projects then exit
  if {$exported_projects == 0} {
    puts "### There are no exported Vivado projects in the $vivado_dir directory ###"
    puts "You must build and export a Vivado project before building the Vitis workspace."
    exit
  }

  puts "There were $exported_projects exported project(s) found in the $vivado_dir directory."
  puts "Creating Vitis workspace."
  
  # Create "boot" directory if it doesn't already exist
  if {[file exists "./boot"] == 0} {
    file mkdir "./boot"
  }
  
  # Set the workspace directory
  set vitis_dir [pwd]
  setws $vitis_dir
  
  # Add local Vitis repo for our locally copied driver for the Gen3 designs
  puts "Adding Vitis repo to the workspace."
  repo -set "../EmbeddedSw"

  # Add each Vivado project to Vitis workspace
  foreach {vivado_folder} $vivado_proj_list {
    # Get the name of the board
    set board_name [string map {"_pcie" ""} $vivado_folder]
    # Path of the XSA file
    set xsa_file "$vivado_dir/$vivado_folder/${vivado_folder}_wrapper.xsa"
    set xsa_filename_only [lindex [split $xsa_file /] end]
    set hw_project_name [lindex [split $xsa_filename_only .] 0]
    # Make sure that the Vivado project has been exported
    if {[file exists $xsa_file] == 0} {
      puts "Vivado project $vivado_folder has not been exported."
      continue
    }
    # Create the application name
    set app_name "${board_name}$app_postfix"
    # If the application has already been created, then skip
    if {[file exists "$app_name"] == 1} {
      puts "Application already exists for Vivado project $vivado_folder."
      continue
    }
    # Create the platform for this Vivado project
    puts "Creating Platform for $vivado_folder."
    platform create -name ${hw_project_name} -hw ${xsa_file}
    platform write
    set proc_instance [get_processor_name ${xsa_file}]
    # Microblaze and Zynq ARM are 32-bit, ZynqMP ARM are 64-bit processors
    if {[str_contains $proc_instance "psu_cortex"]} {
      set arch_bit "64-bit"
    } else {
      set arch_bit "32-bit"
    }
    # Create a standalone domain
    domain create -name {standalone_domain} \
      -display-name "standalone on $proc_instance" \
      -os {standalone} \
      -proc $proc_instance \
      -runtime {cpp} \
      -arch $arch_bit \
      -support-app {empty_application}
    platform write
    platform active ${hw_project_name}
    # Enable the FSBL for Zynq
    if {[str_contains $proc_instance "ps7_cortex"]} {
      domain active {zynq_fsbl}
    # Enable the FSBL and PMU FW for ZynqMP
    } elseif {[str_contains $proc_instance "psu_cortex"]} {
      domain active {zynqmp_fsbl}
      domain active {zynqmp_pmufw}
    }
    domain active {standalone_domain}
    platform generate
    # Generate the empty application
    puts "Creating application $app_name."
    app create -name $app_name \
      -template {Empty Application} \
      -platform ${hw_project_name} \
      -domain {standalone_domain}
    # If the hardware contains the AXI MM PCIe block
    if {[design_contains_ip ${xsa_file} "axi_pcie"] == 1} {
      # Copy the Gen2 application from common/src
      file copy "common/src/pcie_gen2_enumerate.c" ${app_name}/src
	  # else if it contains the AXI Bridge for PCIe Gen3 block
    } elseif {[design_contains_ip ${xsa_file} "axi_pcie3"] == 1} {
      # Copy the Gen3 application from common/src
      file copy "common/src/pcie_gen3_enumerate.c" ${app_name}/src
    # else it contains XDMA
	  } else {
      # Copy the XDMA application from common/src
      file copy "common/src/xdmapcie_rc_enumerate_example.c" ${app_name}/src
    }
    # For Microblaze designs, modify the linker script to put
    # all sections in local mem
    # For Zynq designs, modify linker script to put all sections in DDR
    if {[str_contains $proc_instance "microblaze"]} {
      linker_script_to_local_mem ${app_name}/src/lscript.ld
    } elseif {[str_contains $proc_instance "ps7_cortex"]} {
      linker_script_to_ddr_mem ${app_name}/src/lscript.ld
    }
    # Build the application
    puts "Building application $app_name."
    app build -name $app_name
    puts "Building system ${app_name}_system."
    sysproj build -name ${app_name}_system
    
    # Create or copy the boot file
    # Make sure the application has been compiled
    if {[file exists "./${app_name}/Debug/${app_name}.elf"] == 0} {
      puts "Application ${app_name} FAILED to compile."
      continue
    }
    
    # If all required files exist, then generate boot files
    # Create directory for the boot file if it doesn't already exist
    if {[file exists "./boot/$board_name"] == 0} {
      file mkdir "./boot/$board_name"
    }
	
    # For Microblaze designs
    if {[str_contains $proc_instance "microblaze"]} {
      puts "Generating combined bitstream/elf file for $board_name project."
      # Generate the download.bit file with .elf
      exec updatemem --bit "../Vivado/${vivado_folder}/${vivado_folder}.runs/impl_1/${vivado_folder}_wrapper.bit" \
        --meminfo "../Vivado/${vivado_folder}/${vivado_folder}.runs/impl_1/${vivado_folder}_wrapper.mmi" \
        --data "./${app_name}/Debug/${app_name}.elf" \
        --proc "${vivado_folder}_i/microblaze_0" \
        -force --out "./boot/${board_name}/${board_name}.bit"
    # For Zynq and Zynq MP designs
    } else {
      puts "Copying the BOOT.BIN file to the ./boot/${board_name} directory."
      # Copy the already generated BOOT.bin file
      set bootbin_file "./${app_name}_system/Debug/sd_card/BOOT.bin"
      if {[file exists $bootbin_file] == 1} {
        file copy -force $bootbin_file "./boot/${board_name}"
      } else {
        puts "No BOOT.bin file for ${app_name}."
      }
    }
  }
}
  
# Checks all applications
proc check_apps {} {
  global app_postfix
  # Set the workspace directory
  setws [pwd]
  puts "Checking build status of all applications:"
  # Get list of applications
  foreach {app_dir} [glob -type d "./*$app_postfix"] {
    # Get the app name
    set app_name [lindex [split $app_dir /] end]
    if {[file exists "$app_dir/Debug/${app_name}.elf"] == 1} {
      puts "  ${app_name} was built successfully"
    } else {
      puts "  ERROR: ${app_name} failed to build"
    }
  }
}
  
# Copy original driver sources into the local Vitis repo
puts "Building the local Vitis repo from original sources"
fill_local_libraries

# Create the Vitis workspace
puts "Creating the Vitis workspace"
create_vitis_ws
check_apps

exit
