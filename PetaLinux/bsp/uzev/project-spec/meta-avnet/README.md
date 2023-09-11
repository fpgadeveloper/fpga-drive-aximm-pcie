# meta-avnet
Yocto layer that can be added on top of a Petalinux Project to add:
- Avnet Machine Configurations
- Avnet Tools and Programs
- Avnet Images, to include extra packages for Avnet boards' rootfs.

To use it: 
- clone this repository in the project-spec/ folder inside your Petalinux project
- in Petalinux config, 'Yocto Settings'/'User Layers', add a new layer with '${PROOT}/project-spec/meta-avnet'
- in Petalinux config, change the YOCTO_MACHINE_NAME to use an Avnet Machine ('u96v2-sbc' for example)
- then you can use 'petalinux-build -c avnet-image-minimal' to build your BSP
