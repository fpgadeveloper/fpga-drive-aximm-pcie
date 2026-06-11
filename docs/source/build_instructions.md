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

Additionally, some designs use IP cores that are licensed separately from the Vivado edition itself (for example: TEMAC, XXV Ethernet, HDMI). The **IP License** column in the tables below indicates the designs that require such a license to generate a bitstream; evaluation licenses are generally available from AMD for testing.


## Target designs

This repo contains several designs that target the various supported development boards and their
FMC connectors. The table below lists the target design name, the M2 ports supported by the design and 
the FMC connector on which to connect the mezzanine card.

{% for group in data.groups %}
    {% set designs_in_group = [] %}
    {% for design in data.designs %}
        {% if design.group == group.label and design.publish %}
            {% set _ = designs_in_group.append(design.label) %}
        {% endif %}
    {% endfor %}
    {% if designs_in_group | length > 0 %}
### {{ group.name }} designs

| Target board        | Target design     | M.2 Slot 1<br>PCIe Lanes  | M.2 Slot 2<br>PCIe Lanes  | FMC Slot    | Vivado<br> Edition | IP<br>License |
|---------------------|-------------------|---------------------------|---------------------------|-------------|-----|-----|
{% for design in data.designs %}{% if design.group == group.label and design.publish %}| [{{ design.board }}]({{ design.link }}) | `{{ design.label }}` | {{ design.lanes[0] }} | {{ design.lanes[1] | default("-") }} | {{ design.connector }} | {{ "Enterprise" if design.license else "Standard 🆓" }} | {{ "Required" if design.ip_license else "-" }} |
{% endif %}{% endfor %}
{% endif %}
{% endfor %}

Notes:

1. The Vivado Edition column indicates which designs are supported by the Vivado *Standard* Edition, the
   FREE edition which can be used without a license. Vivado *Enterprise* Edition requires
   a license however a 30-day evaluation license is available from the AMD Xilinx Licensing site.
   
## Cross-platform build runner (recommended)

The designs are built with the `build.py` runner at the repo root — a single
interface that works on both Windows (git bash) and Linux. The `build.sh`
shim locates a suitable Python 3 automatically (including the interpreter
bundled with the AMD tools):

```
cd fpga-drive-aximm-pcie
./build.sh list                            # list targets and attributes
./build.sh xsa --target <target>        # Vivado project + bitstream + XSA
./build.sh standalone --target <target>   # + Vitis baremetal boot image
./build.sh all --target <target>  # + PetaLinux image, gather zips (Linux only)
./build.sh status --target <target>        # show per-stage artifact state
./build.sh clean --target <target>         # delete generated outputs
```

On Windows you can also run the same commands **without git bash**, from
Command Prompt or PowerShell, using `build.bat` (e.g. `build.bat xsa
--target <target>`).

Stages whose outputs already exist are skipped on re-run, so the same
command continues an interrupted build. On Windows, the PetaLinux and Yocto
stages are refused up front with the exact Linux hand-off command. For
Versal targets on Windows, the runner verifies that the project path fits
within the 260-character Windows path limit *before* building, and explains
the `subst` workaround if it does not.

```{attention} The `make` interface described in the sections below still
works on Linux — each Makefile is now a thin wrapper around `build.sh` —
but it is deprecated and will be removed at the next version update.
```

## Windows users

Windows users will be able to build the Vivado projects and compile the standalone applications,
however Linux is required to build the embedded Linux images (PetaLinux or Yocto). 
The recommended way to build on Windows is the [build runner](#cross-platform-build-runner-recommended)
run from git bash: `./build.sh standalone --target <target>`.

```{tip} If you wish to build the PetaLinux projects,
we recommend that you build the entire project (including the Vivado project) on a machine (either 
physical or virtual) running one of the [supported Linux distributions].
```

## Linux users

These projects can be built using a machine (either physical or virtual) with one of the 
[supported Linux distributions].

An embedded Linux image can be built with either of two flows: **PetaLinux** or the
**Yocto / EDF** flow (AMD's Embedded Development Framework, the announced successor to
PetaLinux). Both are driven by a single `make` command and produce an equivalent image — see
[build PetaLinux](#build-petalinux-project-in-linux) or
[build Yocto](#build-yocto-project-in-linux) below.

```{attention} The PetaLinux flow for this repository is being retired. Version 2025.2 is
the last tool release for which we will support PetaLinux; from the next tool version onward,
Linux images will be built with the Yocto / EDF flow only. New work should use the Yocto flow.
```

```{tip} The build steps can be completed in the order shown below, or
you can go directly to the Linux build instructions
([PetaLinux](#build-petalinux-project-in-linux) or [Yocto](#build-yocto-project-in-linux))
to build the Vivado and Linux projects with a single command.
```

### Build Vivado project in Linux

1. Open a command terminal and launch the setup script for Vivado:
   ```
   source <path-to-xilinx-tools>/2025.2/Vivado/settings64.sh
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
   {% for design in data.designs if design.publish %} `{{ design.label }}`{{ ", " if not loop.last else "." }} {% endfor %}
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
   source <path-to-xilinx-tools>/2025.2/Vitis/settings64.sh
   ```
2. To build the Vitis workspace, `cd` to the Vitis directory in the repo,
   then run make to create the Vitis workspace and compile the standalone application:
   ```
   cd fpga-drive-aximm-pcie/Vitis
   make workspace TARGET=<target>
   ```
   Valid target labels for the workspaces are:
   {% for design in data.designs if design.publish %}{% if design.baremetal %} `{{ design.label }}`{{ ", " if not loop.last else "." }} {% endif %}{% endfor %}
   You will find the Vitis workspace in the folder `Vitis/<target>_workspace`.

### Build PetaLinux project in Linux

These steps will build the PetaLinux project for the target design. You are not required to have built the
Vivado design before following these steps, as the Makefile triggers the Vivado build for the corresponding
design if it has not already been done.

1. Launch the setup script for Vivado (only if you skipped the Vivado build steps above):
   ```
   source <path-to-xilinx-tools>/2025.2/Vivado/settings64.sh
   ```
2. Launch PetaLinux by sourcing the `settings.sh` bash script, eg:
   ```
   source <path-to-petalinux-install>/2025.2/settings.sh
   ```
3. Build the PetaLinux project for your specific target platform by running the following
   command, replacing `<target>` with a valid value from below:
   ```
   cd PetaLinux
   make petalinux TARGET=<target>
   ```
   Valid target labels for PetaLinux projects are:
   {% for design in data.designs if design.petalinux and design.publish %} `{{ design.label }}`{{ ", " if not loop.last else "." }} {% endfor %}
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

### Build Yocto project in Linux

These steps build the Yocto / EDF image for the target design, using AMD's recommended
`gen-machineconf` `parse-sdt` flow. As with PetaLinux, you are not required to have built the
Vivado design first — the Makefile triggers the Vivado build for the corresponding design if it
has not already been done.

You will need [Google's `repo` tool](https://gerrit.googlesource.com/git-repo/) on your `PATH`.

1. Launch the setup script for Vivado (only if you skipped the Vivado build steps above):
   ```
   source <path-to-xilinx-tools>/2025.2/Vivado/settings64.sh
   ```
2. Launch the setup script for Vitis. The Yocto flow uses `xsct`/`sdtgen` (which ship with Vitis,
   not PetaLinux) to generate a System Device Tree from the XSA:
   ```
   source <path-to-xilinx-tools>/2025.2/Vitis/settings64.sh
   ```
3. Build the Yocto image for your target by running the following command, replacing `<target>`
   with a valid value from below:
   ```
   cd Yocto
   make yocto TARGET=<target>
   ```
   Valid target labels for Yocto builds are:
   {% for design in data.designs if design.yocto and design.publish %} `{{ design.label }}`{{ ", " if not loop.last else "." }} {% endfor %}
   The first build of a target runs `repo sync` (several GB of git history) and bitbake from
   scratch, so it takes a while; subsequent builds are incremental. The output products
   (`BOOT.BIN`, the kernel, `boot.scr`, `system.dtb`, `rootfs.wic.xz`) are gathered into
   `Yocto/<target>/images/linux/`.

### Yocto offline build

To build the Yocto projects offline (or simply faster), point the build at a locally extracted
AMD sstate-cache mirror.

1. Download the sstate-cache artefacts from the Xilinx downloads site and extract them to a single
   location, for example `/home/user/yocto-sstate`, leaving the following directory structure:
   ```
   /home/user/yocto-sstate
                          +---  aarch64       (Zynq UltraScale+ and Versal)
                          +---  arm           (Zynq-7000)
                          +---  microblaze    (PMU/PLM firmware)
                          +---  downloads
   ```
2. Create a text file called `offline.txt` in the `Yocto` directory of the repository containing a
   single line with that path, written with NO TRAILING FORWARD SLASH:
   ```
   /home/user/yocto-sstate
   ```

`make yocto` will then auto-detect which architecture sub-directories are present and configure
the build to use the mirror.

[supported Linux distributions]: https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment

