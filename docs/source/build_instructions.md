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

Some of the designs in this repository target dev boards for which a license is required to generate a bitstream. 
Others can be built with the Vivado ML Standard Edition **without a license**. The table of target designs in the 
following section contains a column specifying which designs require a license, and which can be built without a 
license.

## Target designs

This repo contains several designs that target the various supported development boards and their
FMC connectors. The table below lists the target design name, the M2 ports supported by the design and 
the FMC connector on which to connect the mezzanine card.

{% for group in data.groups %}
    {% set designs_in_group = [] %}
    {% for design in data.designs %}
        {% if design.group == group.label and design.publish != "NO" %}
            {% set _ = designs_in_group.append(design.label) %}
        {% endif %}
    {% endfor %}
    {% if designs_in_group | length > 0 %}
### {{ group.name }} designs

| Target board        | Target design     | M.2 Slot 1<br>PCIe Lanes  | M.2 Slot 2<br>PCIe Lanes  | FMC Slot    | License<br> required |
|---------------------|-------------------|---------------------------|---------------------------|-------------|-----|
{% for design in data.designs %}{% if design.group == group.label and design.publish != "NO" %}| [{{ design.board }}]({{ design.link }}) | `{{ design.label }}` | {{ design.lanes[0] }} | {{ design.lanes[1] | default("-") }} | {{ design.connector }} | {{ design.license }} |
{% endif %}{% endfor %}
{% endif %}
{% endfor %}

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
3. In the `Vivado` directory, double click on the `build-vivado.bat` batch file.
   You will be prompted to select a target design to build. You will find the project in
   the folder `Vivado/<target>`.
4. Run Vivado and open the project that was just created.
5. Click Generate bitstream.
6. When the bitstream is successfully generated, select **File->Export->Export Hardware**.
   In the window that opens, tick **Include bitstream** and use the default name and location
   for the XSA file.

### Build Vitis workspace in Windows

Before running these steps, you must first build and export the Vivado project as described above.

1. Return to Windows Explorer and browse to the Vitis directory in the repo.
2. Double click the `build-vitis.bat` batch file. You will be prompted to select a target design.
   A Vitis workspace with hardware platform and software application will be created for the
   selected target design. You will find the Vitis workspace in the folder `Vitis/<target>_workspace`.

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
   source <path-to-vivado-install>/2024.1/settings64.sh
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
   Valid target labels are:
   {% for design in data.designs %} `{{ design.label }}`{{ ", " if not loop.last else "." }} {% endfor %}
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

The following steps are required if you wish to build and run the [standalone application](stand_alone). You can
skip to the following section if you instead want to use PetaLinux. You are not required to have built the
Vivado design before following these steps, as the Makefile triggers the Vivado build for the corresponding
design if it has not already been done.

1. Launch the setup scripts for Vitis:
   ```
   source <path-to-vitis-install>/2024.1/settings64.sh
   ```
2. To build the Vitis workspace, `cd` to the Vitis directory in the repo,
   then run make to create the Vitis workspace and compile the standalone application:
   ```
   cd fpga-drive-aximm-pcie/Vitis
   make workspace TARGET=<target>
   ```
   Valid target labels for the workspaces are:
   {% for design in data.designs %}{% if design.baremetal == "YES" %} `{{ design.label }}`{{ ", " if not loop.last else "." }} {% endif %}{% endfor %}
   You will find the Vitis workspace in the folder `Vitis/<target>_workspace`.

### Build PetaLinux project in Linux

These steps will build the PetaLinux project for the target design. You are not required to have built the
Vivado design before following these steps, as the Makefile triggers the Vivado build for the corresponding
design if it has not already been done.

1. Launch the setup script for Vivado (only if you skipped the Vivado build steps above):
   ```
   source <path-to-vivado-install>/2024.1/settings64.sh
   ```
2. Launch PetaLinux by sourcing the `settings.sh` bash script, eg:
   ```
   source <path-to-petalinux-install>/2024.1/settings.sh
   ```
3. Build the PetaLinux project for your specific target platform by running the following
   command, replacing `<target>` with a valid value from below:
   ```
   cd PetaLinux
   make petalinux TARGET=<target>
   ```
   Valid target labels for PetaLinux projects are:
   {% for design in data.designs %}{% if design.petalinux == "YES" %} `{{ design.label }}`{{ ", " if not loop.last else "." }} {% endif %}{% endfor %}
   Note that if you skipped the Vivado build steps above, the Makefile will first generate and
   build the Vivado project, and then build the PetaLinux project.

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
3. Create a text file called `offline.txt` in the `PetaLinux` directory of the project repository. The file should contain
   a single line of text specifying the path where you extracted the sstate-cache files. In this example, the contents of 
   the file would be:
   ```
   /home/user/petalinux-sstate
   ```
   It is important that the file contain only one line and that the path is written with NO TRAILING 
   FORWARD SLASH.

Now when you use `make` to build the PetaLinux projects, they will be configured for offline build.

[supported Linux distributions]: https://docs.xilinx.com/r/2022.1-English/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment



