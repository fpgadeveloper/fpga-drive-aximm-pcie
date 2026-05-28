# system-conf.dtsi was a PetaLinux-generated XSA-extract include; it's
# not produced in our EDF flow (we use the validated AMD MACHINE instead
# of gen-machineconf). Keep only the system-user.dtsi include.
EXTRA_DT_INCLUDE_FILES:append:linux = " system-user.dtsi"
EXTRA_DT_INCLUDE_FILES:append:linux-gnueabi = " system-user.dtsi"
