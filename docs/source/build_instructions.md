# Build instructions

## Source code

The source code for the reference designs is managed on this Github repository:

* [https://github.com/fpgadeveloper/fpga-drive-aximm-pcie](https://github.com/fpgadeveloper/fpga-drive-aximm-pcie)

To get the code, you can follow the link and use the **Download ZIP** option, or you can clone it
using this command:
```
git clone https://github.com/fpgadeveloper/fpga-drive-aximm-pcie.git
```

## License requirements

The designs for the boards listed below **require a license** to build. To build the designs for these boards,
you will need to either buy a license or download a 30-day evaluation license for Vivado ML Enterprise Edition:

* KC705
* KCU105
* VC707
* VC709
* VCU118
* ZC706
* ZCU111
* ZCU208

The designs for all of the remaining [target boards](supported_carriers) can be built with the Vivado ML Standard 
Edition **without a license**. That includes the following boards:

* PicoZed 7015 and 7030
* UltraZed-EV carrier
* ZCU104
* ZCU106

## Target designs

This repo contains several designs that target the various supported development boards and their
FMC connectors. The table below lists the target design name, the M2 ports supported by the design and 
the FMC connector on which to connect the FPGA Drive FMC Gen4.

| Target design     | M2 ports   | Target board and connector     |
|-------------------|------------|--------------------------------|
| `kc705_hpc`       | SSD1       | KC705, HPC connector           |
| `kc705_lpc`       | SSD1       | KC705, LPC connector           |
| `kcu105_hpc`      | SSD1       | KCU105, HPC connector          |
| `kcu105_hpc_dual` | SSD1,SSD2  | KCU105, HPC connector          |
| `kcu105_lpc`      | SSD1       | KCU105, LPC connector          |
| `pz_7015`         | SSD1       | PicoZed 7015                   |
| `pz_7030`         | SSD1       | PicoZed 7030                   |
| `uzev_dual`       | SSD1,SSD2  | UltraZed-EV carrier            |
| `vc707_hpc1`      | SSD1       | VC707, HPC1 connector          |
| `vc707_hpc2`      | SSD1       | VC707, HPC2 connector          |
| `vc709_hpc`       | SSD1       | VC709                          |
| `vcu118`          | SSD1       | VCU118                         |
| `vcu118_dual`     | SSD1,SSD2  | VCU118                         |
| `zc706_hpc`       | SSD1       | ZC706, HPC connector           |
| `zc706_lpc`       | SSD1       | ZC706, HPC connector           |
| `zcu104`          | SSD1       | ZCU104                         |
| `zcu106_hpc0`     | SSD1       | ZCU106, HPC0 connector         |
| `zcu106_hpc0_dual`| SSD1,SSD2  | ZCU106, HPC0 connector         |
| `zcu106_hpc1`     | SSD1       | ZCU106, HPC1 connector         |
| `zcu111`          | SSD1       | ZCU111                         |
| `zcu111_dual`     | SSD1,SSD2  | ZCU111                         |
| `zcu208`          | SSD1       | ZCU208                         |
| `zcu208_dual`     | SSD1,SSD2  | ZCU208                         |

## Windows users

Windows users will be able to build the Vivado projects and compile the standalone applications,
however Linux is required to build the PetaLinux projects. 

```{tip} If you wish to build the PetaLinux projects,
we recommend that you build the entire project (including the Vivado project) on a machine (either 
physical or virtual) running one of the [supported Linux distributions].
```

### Build Vivado project in Windows

1. Download the repo as a zip file and extract the files to a directory
   on your hard drive --OR-- clone the repo to your hard drive
2. Open Windows Explorer, browse to the repo files on your hard drive.
3. In the `Vivado` directory, you will find multiple batch files (.bat).
   Double click on the batch file that corresponds to your hardware,
   for example, double-click `build-zcu104.bat` if you are using the ZCU104.
   This will generate a Vivado project for your hardware platform.
4. Run Vivado and open the project that was just created.
5. Click Generate bitstream.
6. When the bitstream is successfully generated, select **File->Export->Export Hardware**.
   In the window that opens, tick **Include bitstream** and use the default name and location
   for the XSA file.

### Build Vitis workspace in Windows

1. Return to Windows Explorer and browse to the Vitis directory in the repo.
2. Double click the `build-vitis.bat` batch file. The batch file will run the
   `build-vitis.tcl` script and build the Vitis workspace containing the hardware
   design and the software application.

## Linux users

These projects can be built using a machine (either physical or virtual) with one of the 
[supported Linux distributions].

```{tip} The build steps can be completed in the order shown below, or
you can go directly to the [build PetaLinux](#build-petalinux-project-in-linux) instructions below
to build the Vivado and PetaLinux projects with a single command.
```

### Build Vivado project in Linux

1. Open a command terminal and launch the setup script for Vivado:
   ```
   source <path-to-vivado-install>/2022.1/settings64.sh
   ```
2. Clone the Git repository and `cd` into the `Vivado` folder of the repo:
   ```
   git clone https://github.com/fpgadeveloper/fpga-drive-aximm-pcie.git
   cd fpga-drive-aximm-pcie/Vivado
   ```
3. Run make to create the Vivado project for the target board. You must replace `<target>` with a valid
   target (alternatively, skip to step 5):
   ```
   make project TARGET=<target>
   ```
   Valid targets are: 
   `kc705_hpc`, 
   `kc705_lpc`, 
   `kcu105_hpc`, 
   `kcu105_hpc_dual`, 
   `kcu105_lpc`, 
   `pz_7015`, 
   `pz_7030`, 
   `uzev_dual`, 
   `vc707_hpc1`,
   `vc707_hpc2`,
   `vc709_hpc`,
   `vcu118`, 
   `vcu118_dual`, 
   `zc706_hpc`, 
   `zc706_lpc`, 
   `zcu104`, 
   `zcu106_hpc0`, 
   `zcu106_hpc0_dual`, 
   `zcu106_hpc1`, 
   `zcu111`, 
   `zcu111_dual`, 
   `zcu208`, and 
   `zcu208_dual`.
   That will create the Vivado project and block design without generating a bitstream or exporting to XSA.
4. Open the generated project in the Vivado GUI and click **Generate Bitstream**. Once the build is
   complete, select **File->Export->Export Hardware** and be sure to tick **Include bitstream** and use
   the default name and location for the XSA file.
5. Alternatively, you can create the Vivado project, generate the bitstream and export to XSA (steps 3 and 4),
   all from a single command:
   ```
   make xsa TARGET=<target>
   ```
   
### Build Vitis workspace in Linux

The following steps are required if you wish to build and run the [standalone application](standalone). You can
skip to the following section if you instead want to use PetaLinux. We are assuming that you have 
completed the above steps and an XSA file has been generated for your selected target.

1. Launch the setup scripts for Vitis:
   ```
   source <path-to-vitis-install>/2022.1/settings64.sh
   ```
2. To build the Vitis workspace, `cd` to the Vitis directory in the repo,
   then run make to create the Vitis workspace and compile the standalone application:
   ```
   cd fpga-drive-aximm-pcie/Vitis
   make workspace TARGET=<target>
   ```

### Build PetaLinux project in Linux

These steps will build the PetaLinux project for the target design. You are not required to have built the
Vivado design before following these steps, as the Makefile triggers the Vivado build for the corresponding
design if it has not already been done.

1. Launch the setup script for Vivado (only if you skipped the Vivado build steps above):
   ```
   source <path-to-vivado-install>/2022.1/settings64.sh
   ```
2. Launch PetaLinux by sourcing the `settings.sh` bash script, eg:
   ```
   source <path-to-petalinux-install>/2022.1/settings.sh
   ```
3. Build the PetaLinux project for your specific target platform by running the following
   command, replacing `<target>` with a valid value from below:
   ```
   cd PetaLinux
   make petalinux TARGET=<target>
   ```
   Valid targets are: 
   `kc705_hpc`, 
   `kc705_lpc`, 
   `kcu105_hpc`, 
   `kcu105_hpc_dual`, 
   `kcu105_lpc`, 
   `pz_7015`, 
   `pz_7030`, 
   `uzev_dual`, 
   `vcu118`, 
   `vcu118_dual`, 
   `zc706_hpc`, 
   `zc706_lpc`, 
   `zcu104`, 
   `zcu106_hpc0`, 
   `zcu106_hpc0_dual`, 
   `zcu106_hpc1`, 
   `zcu111`, 
   `zcu111_dual`, 
   `zcu208`, and 
   `zcu208_dual`.
   Note that if you skipped the Vivado build steps above, the Makefile will first generate and
   and build the Vivado project, and then build the PetaLinux project.

### PetaLinux offline build

If you need to build the PetaLinux projects offline (without an internet connection), you can
follow these instructions.

1. Download the sstate-cache artefacts from the Xilinx downloads site (the same page where you downloaded
   PetaLinux tools). There are four of them:
   * aarch64 sstate-cache (for ZynqMP designs)
   * arm sstate-cache (for Zynq designs)
   * microblaze sstate-cache (for Microblaze designs)
   * Downloads (for all designs)
2. Extract the contents of those files to a single location on your hard drive, for this example
   we'll say `/home/user/petalinux-sstate`. That should leave you with the following directory 
   structure:
   ```
   /home/user/petalinux-sstate
                             +---  aarch64
                             +---  arm
                             +---  downloads
                             +---  microblaze
   ```
3. Create a text file called `offline.txt` that contains a single line of text. The single line of text
   should be the path where you extracted the sstate-cache files. In this example, the contents of 
   the file would be:
   ```
   /home/user/petalinux-sstate
   ```
   It is important that the file contain only one line and that the path is written with NO TRAILING 
   FORWARD SLASH.

Now when you use `make` to build the PetaLinux projects, they will be configured for offline build.

[supported Linux distributions]: https://docs.xilinx.com/r/2022.1-English/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment
[FPGA Drive FMC Gen4]: https://fpgadrive.com


