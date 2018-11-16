#!/usr/bin/tclsh

# Description
# -----------
# This Tcl script will create an SDK workspace with software applications for each of the
# exported hardware designs in the ../Vivado directory.

# axipcie Driver modifications
# ----------------------------
# Some of the Vivado designs in this project use the AXI Memory Mapped to PCIe Gen2 IP
# and others use the AXI Bridge for PCIe Gen3 IP. The XSDK comes with a driver for the Gen2
# core that is called "axipcie". The BSPs for projects using the Gen2 core refer to that 
# driver. You can find the driver sources in the XSDK installation files:
#
# C:\Xilinx\SDK\<version>\data\embeddedsw\XilinxProcessorIPLib\drivers\axipcie_v3_1
#
# The XSDK does not currently supply a driver for the Gen3 core. However, there are enough
# similarities between the Gen2 and Gen3 cores that we can get away with using a modified 
# version of the "axipcie" driver, for doing some simple things such as link-up detection,
# determining link speed and width, and enumerating PCIe devices with the Gen3 core.
# 
# We create this "Gen3 version" of the driver by making a local copy of the "axipcie" driver
# sources and modifying the ".mdd" file, specifying that the driver supports the Gen3 core.
# For SDK to be aware of our locally copied driver, we set the SDK's "repo" path to the path 
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
  # Xilinx SDK install directory
  set sdk_dir $::env(XILINX_SDK)
  # For each of the custom driver versions in our local repo
  foreach drv_dir [glob -type d "../EmbeddedSw/XilinxProcessorIPLib/drivers/*"] {
    # Work out the original version library directory name by removing the appended "9"
    set lib_name [string trimright [lindex [split $drv_dir /] end] "9"]
    set orig_dir "$sdk_dir/data/embeddedsw/XilinxProcessorIPLib/drivers/$lib_name"
    puts "Copying files from $orig_dir to $drv_dir"
    # Copy the original files to local repo, without overwriting existing code
    copy-r $orig_dir $drv_dir
  }
}

# Add a hardware design to the SDK workspace
proc add_hw_to_sdk {vivado_folder} {
  global vivado_dir
  set hdf_filename [lindex [glob -dir $vivado_dir/$vivado_folder/$vivado_folder.sdk *.hdf] 0]
  set hdf_filename_only [lindex [split $hdf_filename /] end]
  set top_module_name [lindex [split $hdf_filename_only .] 0]
  set hw_project_name ${top_module_name}_hw_platform_0
  # If the hw project does not already exist in the SDK workspace, then create it
  if {[file exists "$hw_project_name"] == 0} {
    createhw -name ${hw_project_name} -hwspec $hdf_filename
  }
  return $hw_project_name
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


# ============================================================
#                IP NAME       DRIVER NAME  DRIVER VERSION
# ============================================================
#              axi_dma_0            axidma       9.3
#              ps7_afi_0           generic       2.0
#              ps7_afi_1           generic       2.0
#              ps7_afi_2           generic       2.0
#              ps7_afi_3           generic       2.0
#   ps7_coresight_comp_0   coresightps_dcc       1.3
#              ps7_ddr_0             ddrps       1.0
#             ps7_ddrc_0           generic       2.0
#          ps7_dev_cfg_0            devcfg       3.4
#             ps7_dma_ns             dmaps       2.2
#              ps7_dma_s             dmaps       2.2
#         ps7_ethernet_0            emacps       3.3
#      ps7_globaltimer_0           generic       2.0
#             ps7_gpio_0            gpiops       3.1
#              ps7_gpv_0           generic       2.0
#        ps7_intc_dist_0           generic       2.0
#   ps7_iop_bus_config_0           generic       2.0
#         ps7_l2cachec_0           generic       2.0
#             ps7_ocmc_0           generic       2.0
#            ps7_pl310_0           generic       2.0
#              ps7_pmu_0           generic       2.0
#             ps7_qspi_0            qspips       3.3
#      ps7_qspi_linear_0           generic       2.0
#              ps7_ram_0           generic       2.0
#              ps7_ram_1           generic       2.0
#             ps7_scuc_0           generic       2.0
#           ps7_scugic_0            scugic       3.4
#         ps7_scutimer_0          scutimer       2.1
#           ps7_scuwdt_0            scuwdt       2.1
#               ps7_sd_0              sdps       3.0
#             ps7_slcr_0           generic       2.0
#              ps7_ttc_0             ttcps       3.1
#             ps7_uart_1            uartps       3.2
#              ps7_usb_0             usbps       2.4
#             ps7_xadc_0            xadcps       2.2
#         ps7_cortexa9_0      cpu_cortexa9       2.3
proc get_drv_version {bsp_prj drv_name} {
  set drivers [getdrivers -bsp $bsp_prj]
  # For each line of the peripherals table
  foreach line [split $drivers "\n"] {
    set values [regexp -all -inline {\S+} $line]
    # If the 3rd column matches drv_name, then return the version
    if {[lindex $values 1] == $drv_name} {
      return [lindex $values 2]
    }
  }
  return ""
}

# Get latest PCIe enumerate example code filename
proc get_pcie_code_filename {bsp_name} {
  # Xilinx SDK install directory
  set sdk_dir $::env(XILINX_SDK)
  set drv_ver [string map {. _} [get_drv_version $bsp_name "axipcie"]]
  # Return the filename of the example code
  return "$sdk_dir/data/embeddedsw/XilinxProcessorIPLib/drivers/axipcie_v${drv_ver}/examples/xaxipcie_rc_enumerate_example.c"
}

# Creates the .bif file for a Zynq board
proc create_zynq_bif {board_name app_name vivado_name target_dir sdk_dir} {
  set full_sdk_dir [file normalize $sdk_dir]
  regsub -all {/} $full_sdk_dir {\\} full_sdk_dir
  set fd [open "${target_dir}/${board_name}.bif" "w"]
  puts $fd "//arch = zynq; split = false; format = BIN"
  puts $fd "the_ROM_image:"
  puts $fd "\{"
  puts $fd "	\[bootloader\]${full_sdk_dir}\\${board_name}_fsbl\\Debug\\${board_name}_fsbl.elf"
  puts $fd "	${full_sdk_dir}\\${vivado_name}_wrapper_hw_platform_0\\${vivado_name}_wrapper.bit"
  puts $fd "	${full_sdk_dir}\\${app_name}\\Debug\\${app_name}.elf"
  puts $fd "\}"
  close $fd
}

# Creates the .bif file for a Zynq MP board
proc create_zynqmp_bif {board_name app_name vivado_name target_dir sdk_dir} {
  set full_sdk_dir [file normalize $sdk_dir]
  regsub -all {/} $full_sdk_dir {\\} full_sdk_dir
  set fd [open "${target_dir}/${board_name}.bif" "w"]
  puts $fd "//arch = zynqmp; split = false; format = BIN"
  puts $fd "the_ROM_image:"
  puts $fd "\{"
  puts $fd "	\[fsbl_config\]a53_x64"
  puts $fd "	\[bootloader\]${full_sdk_dir}\\${board_name}_fsbl\\Debug\\${board_name}_fsbl.elf"
  puts $fd "	\[destination_device = pl\]${full_sdk_dir}\\${vivado_name}_wrapper_hw_platform_0\\${vivado_name}_wrapper.bit"
  puts $fd "	\[destination_cpu = a53-0\]${full_sdk_dir}\\${app_name}\\Debug\\${app_name}.elf"
  puts $fd "\}"
  close $fd
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

# Creates SDK workspace for a project
proc create_sdk_ws {} {
  global vivado_dir
  global app_postfix
  # First make sure there is at least one exported Vivado project
  set exported_projects 0
  # Get list of Vivado projects
  set vivado_proj_list [get_vivado_projects $vivado_dir]
  # Check each Vivado project for export files
  foreach {vivado_folder} $vivado_proj_list {
    # If the hardware has been exported for SDK
    if {[file exists "$vivado_dir/$vivado_folder/${vivado_folder}.sdk"] == 1} {
      set exported_projects [expr {$exported_projects+1}]
    }
  }
  
  # If no projects then exit
  if {$exported_projects == 0} {
    puts "### There are no exported Vivado projects in the $vivado_dir directory ###"
    puts "You must build and export a Vivado project before building the SDK workspace."
    exit
  }

  puts "There were $exported_projects exported project(s) found in the $vivado_dir directory."
  puts "Creating SDK workspace."
  
  # Set the workspace directory
  setws [pwd]
  
  # Add local SDK repo for our locally copied driver for the Gen3 designs
  puts "Adding SDK repo to the workspace."
  repo -set "../EmbeddedSw"

  # Add each Vivado project to SDK workspace
  foreach {vivado_folder} $vivado_proj_list {
    # Get the name of the board
    set board_name [string replace $vivado_folder [string last _ $vivado_folder end] end ""]
    # Don't create applications for the ZynqMP designs
    if {[str_contains $board_name "zcu"]} {
      puts "No app will be generated for Zynq Ultrascale+ designs"
      continue
    }
    # Create the application name
    set app_name "${board_name}$app_postfix"
    # If the application has already been created, then skip
    if {[file exists "$app_name"] == 1} {
      puts "Application already exists for Vivado project $vivado_folder."
    # If the hardware has been exported for SDK, then create an application for it
    } elseif {[file exists "$vivado_dir/$vivado_folder/${vivado_folder}.sdk"] == 1} {
      puts "Creating application for Vivado project $vivado_folder."
      set hw_project_name [add_hw_to_sdk $vivado_folder]
      set proc_instance [get_processor_name $hw_project_name]
      # Generate the example application
      createapp -name $app_name \
        -app {Hello World} \
        -proc $proc_instance \
        -hwproject ${hw_project_name} \
        -os standalone
      # Delete the hello.c application
      file delete $app_name/src/helloworld.c
      # If the hardware contains the AXI MM PCIe block
      if {[design_contains_ip $hw_project_name "axi_pcie"] == 1} {
        # Copy the Gen2 application from common/src
        file copy "common/src/pcie_gen2_enumerate.c" ${app_name}/src
	    # else it contains the AXI Bridge for PCIe Gen3 block
      } else {
        # Copy the Gen3 application from common/src
        file copy "common/src/pcie_gen3_enumerate.c" ${app_name}/src
	    }
      # For Microblaze designs, modify the linker script to put
      # all sections in local mem
      if {[str_contains $proc_instance "microblaze"]} {
        linker_script_to_local_mem ${app_name}/src/lscript.ld
      }
      # Generate the FSBL for Zynq and Zynq MP designs
      # For Zynq MP designs
      if {[str_contains $proc_instance "psu_cortexa53_"]} {
        createapp -name ${board_name}_fsbl \
          -app {Zynq MP FSBL} \
          -proc $proc_instance \
          -hwproject ${hw_project_name} \
          -os standalone
	    # For Zynq designs
      } elseif {[str_contains $proc_instance "ps7_cortexa9_"]} {
        createapp -name ${board_name}_fsbl \
          -app {Zynq FSBL} \
          -proc $proc_instance \
          -hwproject ${hw_project_name} \
          -os standalone
      }
    } else {
      puts "Vivado project $vivado_folder not exported."
    }
  }
}
  
# Builds all applications
proc build_projects {} {
  # Set the workspace directory
  setws [pwd]
  # Build all
  puts "Building all applications."
  projects -build
}
  
# Creates boot files for all applications
proc create_boot_files {} {
  global vivado_dir
  global app_postfix
  # Set the workspace directory
  setws [pwd]
  
  # Create "boot" directory if it doesn't already exist
  if {[file exists "./boot"] == 0} {
    file mkdir "./boot"
  }
  
  # Get list of Vivado projects
  set vivado_proj_list [get_vivado_projects $vivado_dir]
  
  # Generate boot files for all projects
  foreach {vivado_folder} $vivado_proj_list {
    # Get the name of the board
    set board_name [string replace $vivado_folder [string last _ $vivado_folder end] end ""]
    # Create the application name
    set app_name "${board_name}$app_postfix"
    # Make sure the application has been compiled
    if {[file exists "./${app_name}/Debug/${app_name}.elf"] == 0} {
      puts "ELF does not exist for ${app_name}"
      continue
    }
	
    # Get the processor type
    set proc_instance [get_processor_name "${vivado_folder}_wrapper_hw_platform_0"]
    # For Zynq and Zynq MP designs, make sure that the FSBL exists
    if {[str_contains $proc_instance "microblaze_"] == 0} {
      if {[file exists "./${board_name}_fsbl/Debug/${board_name}_fsbl.elf"] == 0} {
        puts "ELF does not exist for ${board_name}_fsbl"
        continue
      }
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
	# For Zynq MP designs
	} elseif {[str_contains $proc_instance "psu_cortexa53_"]} {
	  puts "Generating BOOT.bin file for Zynq MP $board_name project."
	  # Generate the .bif file
	  create_zynqmp_bif $board_name $app_name $vivado_folder "./boot" "."
	  exec bootgen -image .\\boot\\${board_name}.bif -arch zynqmp -o .\\boot\\${board_name}\\BOOT.bin -w on
	# For Zynq designs
    } else {
	  puts "Generating BOOT.bin file for Zynq $board_name project."
	  # Generate the .bif file
	  create_zynq_bif $board_name $app_name $vivado_folder "./boot" "."
	  exec bootgen -image .\\boot\\${board_name}.bif -arch zynq -o .\\boot\\${board_name}\\BOOT.bin -w on
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
  
# Copy original driver sources into the local SDK repo
puts "Building the local SDK repo from original sources"
fill_local_libraries

# Create the SDK workspace
puts "Creating the SDK workspace"
create_sdk_ws
build_projects
create_boot_files
check_apps


exit
