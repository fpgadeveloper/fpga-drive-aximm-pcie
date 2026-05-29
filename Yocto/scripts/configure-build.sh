#!/usr/bin/env bash
#
# Configure a Yocto workspace's build/ directory. Two flows are supported,
# selected by the FLOW argument ($9):
#
#   gen-machineconf  (AMD's recommended "parse-sdt" path)
#     1. source edf-init-build-env to create build/ with default conf
#     2. add our meta-user layer to bblayers.conf
#     3. generate a System Device Tree (SDT) from the project XSA via xsct/sdtgen
#     4. run `gen-machineconf parse-sdt` on the SDT to generate a *custom*
#        MACHINE whose device tree (PS + PL) is derived directly from the XSA.
#        Changes a customer makes to the PS in Vivado therefore flow straight
#        through XSA -> SDT -> machine.conf -> system device tree -> Linux.
#     5. set MACHINE to the generated name and apply BSP overrides + sstate.
#
#   validated-machine  (legacy path, used by the already-validated boards)
#     Uses a pre-validated AMD MACHINE (e.g. zynqmp-zcu106-sdt-full) pinned in
#     the BSP's local.conf.append, and conveys design-specific PL hardware via a
#     hand-curated system-user.dtsi overlay in the meta-user device-tree.bbappend.
#     gen-machineconf is bypassed. (Versal additionally generates an SDT to feed
#     the PLM/PSM firmware build.)
#
# Args:
#   $1 workspace dir   (must contain edf-init-build-env and sources/)
#   $2 TARGET name     (e.g. zcu104; used as the gen-machineconf machine suffix)
#   $3 BSP dir         (e.g. <repo>/Yocto/bsp/zcu104)
#   $4 XSA file        (absolute path)
#   $5 SSTATE_PATH     (may be empty if no offline cache)
#   $6 SSTATE_ARCH     (e.g. aarch64; only consulted if SSTATE_PATH set)
#   $7 BOOTFILE_PATH   (absolute path to the PL boot artifact:
#                       .bit for zynq/zynqMP (embedded into BOOT.BIN via
#                       xilinx-bootbin) or .pdi for versal (replaces the AMD
#                       reference base PDI). Empty = don't override. Unused by
#                       the gen-machineconf flow, which wires the bitstream/PDI
#                       automatically from the SDT.)
#   $8 TEMPLATE        (the template name from the Yocto Makefile:
#                       zynqMP / versal / zynq / microblaze.)
#   $9 FLOW            (gen-machineconf | validated-machine; default the latter)

set -euo pipefail

WORKSPACE="$1"
TARGET="$2"
BSP_DIR="$3"
XSA="$4"
SSTATE_PATH="$5"
SSTATE_ARCH="$6"
BOOTFILE_PATH="${7:-}"
TEMPLATE="${8:-}"
FLOW="${9:-validated-machine}"

SETUP="$WORKSPACE/edf-init-build-env"

if [ ! -f "$SETUP" ]; then
    echo "ERROR: $SETUP not found. Run init-workspace.sh first." >&2
    exit 1
fi

if [ ! -f "$XSA" ]; then
    echo "ERROR: XSA not found at $XSA" >&2
    exit 1
fi

# Everything below must happen inside a sourced edf-init-build-env shell.
# That script forwards "$@" to poky/oe-init-build-env, which treats the first
# positional arg as the builddir name. We must explicitly pass "build" so
# oe-init-build-env doesn't grab whatever positional args this script was
# invoked with.
cd "$WORKSPACE"
# AMD's edf-init-build-env references $ZSH_NAME without quoting; relax
# `set -u` while sourcing it, then re-enable.
set +u
set -- build
# shellcheck disable=SC1091
source ./edf-init-build-env build
set -u

BUILDDIR="${BUILDDIR:-$WORKSPACE/build}"
CONF_DIR="$BUILDDIR/conf"

# ---- bblayers.conf: add our meta-user layer (before gen-machineconf so the
# meta-user recipes/bbappends are visible to bitbake when it parses) ----------
META_USER_DIR="$BSP_DIR/meta-user"
if ! grep -qsF "$META_USER_DIR" "$CONF_DIR/bblayers.conf"; then
    echo "[configure-build] bblayers.conf += $META_USER_DIR"
    {
        echo ""
        echo "# Added by fpga-drive-aximm-pcie Yocto/scripts/configure-build.sh"
        echo "BBLAYERS += \"$META_USER_DIR\""
    } >> "$CONF_DIR/bblayers.conf"
fi

# ---- helper: emit SSTATE_MIRRORS / SOURCE_MIRROR_URL lines for offline.txt ---
# Reads $SSTATE_PATH; emits one SSTATE_MIRRORS entry per extracted arch subdir.
emit_sstate_mirrors() {
    [ -n "$SSTATE_PATH" ] || return 0
    echo ""
    echo "# offline.txt: $SSTATE_PATH"
    local mirrors_list="" arch_dir arch_name
    for arch_dir in "$SSTATE_PATH"/*/; do
        arch_name=$(basename "$arch_dir")
        case "$arch_name" in
            aarch64|arm|microblaze)
                mirrors_list="${mirrors_list}file://.* file://${SSTATE_PATH}/${arch_name}/PATH \\n "
                ;;
        esac
    done
    if [ -n "$mirrors_list" ]; then
        # shellcheck disable=SC2028
        echo "SSTATE_MIRRORS ?= \"${mirrors_list%\\n }\""
    fi
    if [ -d "$SSTATE_PATH/downloads" ]; then
        echo "SOURCE_MIRROR_URL ?= \"file://$SSTATE_PATH/downloads/\""
        echo "INHERIT += \"own-mirrors\""
    fi
}

# ---- helper: generate a System Device Tree from an XSA via xsct/sdtgen -------
# Sets the global SDT_PATH on success (the dir containing system-top.dts), or
# leaves it empty on failure. Runs xsct in a subshell so anything it puts on
# the environment doesn't leak into the surrounding (bitbake) shell.
generate_sdt() {
    SDT_PATH=""
    if ! command -v xsct >/dev/null 2>&1; then
        echo "[configure-build] WARNING: xsct not on PATH — SDT generation skipped" >&2
        echo "[configure-build]          (source the Vitis settings64.sh before make)" >&2
        return 1
    fi
    local sdt_out="$WORKSPACE/sdt"
    rm -rf "$sdt_out"
    mkdir -p "$sdt_out"
    echo "[configure-build] generating SDT from $XSA via xsct/sdtgen -> $sdt_out"
    if ( xsct -eval "sdtgen set_dt_param -dir $sdt_out -xsa $XSA; sdtgen generate_sdt" ) \
            > "$sdt_out/sdtgen.log" 2>&1 \
       && [ -f "$sdt_out/system-top.dts" ]; then
        SDT_PATH="$sdt_out"
        echo "[configure-build]   SDT generated at $SDT_PATH"
        return 0
    fi
    echo "[configure-build] WARNING: sdtgen failed; see $sdt_out/sdtgen.log" >&2
    return 1
}

MARK_BEGIN="# >>> fpga-drive-aximm-pcie: BEGIN appended local.conf (do not edit) >>>"
MARK_END="# <<< fpga-drive-aximm-pcie: END appended local.conf <<<"
LOCAL_APPEND="$BSP_DIR/conf/local.conf.append"

# Strip any previously appended block so this script is idempotent.
if grep -qF "$MARK_BEGIN" "$CONF_DIR/local.conf"; then
    sed -i "/^$MARK_BEGIN$/,/^$MARK_END$/d" "$CONF_DIR/local.conf"
fi

############################################################################
# FLOW: gen-machineconf (AMD parse-sdt path)
############################################################################
if [ "$FLOW" = "gen-machineconf" ]; then
    # 1. SDT from XSA (mandatory for this flow).
    if ! generate_sdt; then
        echo "ERROR: SDT generation is required for the gen-machineconf flow." >&2
        exit 1
    fi

    # 2. Run gen-machineconf parse-sdt to generate a custom MACHINE. bitbake is
    #    available (we sourced edf-init-build-env) so the tool builds its own
    #    native helpers (kconfig-frontends-native, esw-conf-native, lopper) and
    #    fetches/processes the SDT itself. The bitstream is auto-wired from the
    #    .bit inside the SDT dir (BITSTREAM_PATH); because we do NOT request a PL
    #    overlay (-g), fpga-overlay is left out of MACHINE_FEATURES and the
    #    bitstream is embedded into BOOT.BIN by xilinx-bootbin.
    MACHINE_NAME="fpgadrv-${TARGET}"
    GMC="$WORKSPACE/sources/meta-xilinx/gen-machine-conf/gen-machineconf"
    if [ ! -x "$GMC" ]; then
        echo "ERROR: gen-machineconf not found at $GMC" >&2
        exit 1
    fi
    echo "[configure-build] gen-machineconf parse-sdt -> MACHINE=$MACHINE_NAME"
    python3 "$GMC" \
        --hw-description "$SDT_PATH" \
        --config-dir "$CONF_DIR" \
        --machine-name "$MACHINE_NAME" \
        parse-sdt

    if [ ! -f "$CONF_DIR/machine/$MACHINE_NAME.conf" ]; then
        echo "ERROR: gen-machineconf did not produce conf/machine/$MACHINE_NAME.conf" >&2
        exit 1
    fi

    # 3. local.conf: select the generated MACHINE + apply BSP overrides + sstate.
    {
        echo "$MARK_BEGIN"
        echo "# Custom MACHINE generated by gen-machineconf parse-sdt from the"
        echo "# project XSA (PS + PL device tree derived directly from hardware)."
        echo "MACHINE = \"$MACHINE_NAME\""
        echo ""
        echo "# Recommended by gen-machineconf: tolerate unused meta-virt/security/tpm"
        echo "# layers that the generated baremetal multiconfigs may pull in."
        echo "SKIP_META_VIRT_SANITY_CHECK = \"1\""
        echo "SKIP_META_SECURITY_SANITY_CHECK = \"1\""
        echo "SKIP_META_TPM_SANITY_CHECK = \"1\""
        if [ -f "$LOCAL_APPEND" ]; then
            echo ""
            echo "# from $LOCAL_APPEND"
            cat "$LOCAL_APPEND"
        fi
        emit_sstate_mirrors
        echo "$MARK_END"
    } >> "$CONF_DIR/local.conf"

    echo "[configure-build] build/conf ready in $BUILDDIR (gen-machineconf flow, MACHINE=$MACHINE_NAME)"
    exit 0
fi

############################################################################
# FLOW: validated-machine (legacy path — pinned AMD MACHINE + DT overlay)
############################################################################

# ---- Versal: generate SDT from our XSA via xsct/sdtgen ----------------------
#
# For Versal the design-specific PLM/PSM firmware is built from the SDT
# (system device tree). If we use AMD's reference SDT (downloaded by the
# sdt-artifacts recipe from edf.amd.com), the PLM is compiled for an empty
# vck190 base platform and can't dispatch our design's NPI commands —
# boot fails on the post-bitstream rnpi partition with PLM Error 0x01410000.
#
# Generate an SDT from our XSA here and stash the path. The companion
# bbappend at bsp/<board>/meta-user/recipes-bsp/sdt-artifacts/sdt-artifacts.bbappend
# picks up FPGADRV_SDT_PATH (set in local.conf below) and uses our local
# SDT instead of fetching from edf.amd.com — the plm-firmware and
# psm-firmware multiconfigs then build design-specific binaries.
#
# ZynqMP doesn't need this in the validated flow: the FSBL programs the PL via
# PCAP with a self-contained .bit blob, no NPI dispatch, AMD's reference SDT is fine.
SDT_PATH=""
if [ "$TEMPLATE" = "versal" ]; then
    generate_sdt || true
fi

# ---- local.conf: merge BSP overrides + sstate mirror (idempotent) -----------
# The BSP's local.conf.append pins the validated AMD MACHINE; we just layer our
# settings on top of it here.
{
    echo "$MARK_BEGIN"
    echo "# FPGADRV_TARGET picks a per-target subdir under the BSP's"
    echo "# device-tree/files/ (system-user.dtsi differs per Vivado BD)."
    echo "FPGADRV_TARGET = \"$TARGET\""
    if [ -f "$LOCAL_APPEND" ]; then
        echo "# from $LOCAL_APPEND"
        cat "$LOCAL_APPEND"
    fi
    emit_sstate_mirrors
    if [ -n "$BOOTFILE_PATH" ] && [ -f "$BOOTFILE_PATH" ]; then
        echo ""
        case "$BOOTFILE_PATH" in
            *.bit)
                echo "# Embed our Vivado-built PL bitstream into BOOT.BIN. The"
                echo "# default BIF_BITSTREAM_ATTR is empty for zynqmp (no"
                echo "# bitstream); setting it to \"bitstream\" pulls in"
                echo "# virtual/bitstream, which the recipe below satisfies"
                echo "# from BITSTREAM_PATH."
                echo "BIF_BITSTREAM_ATTR = \"bitstream\""
                echo "BITSTREAM_PATH = \"$BOOTFILE_PATH\""
                ;;
            *.pdi)
                echo "# Override the AMD reference platform PDI (e.g."
                echo "# vck190_base_boot.pdi) with our design's PDI so the PLM"
                echo "# loads FPGA Drive PL on boot. The MACHINE conf assigns"
                echo "# PDI_PATH with =, which would clobber a global override"
                echo "# here; instead expose the path as FPGADRV_PDI_PATH and"
                echo "# let our base-pdi_%.bbappend re-assign PDI_PATH at the"
                echo "# recipe level (processed after MACHINE conf)."
                echo "FPGADRV_PDI_PATH = \"$BOOTFILE_PATH\""
                ;;
        esac
    fi
    if [ -n "$SDT_PATH" ]; then
        echo ""
        echo "# Use the XSA-derived SDT generated above; consumed by"
        echo "# bsp/<board>/meta-user/recipes-bsp/sdt-artifacts/sdt-artifacts.bbappend"
        echo "# to substitute our local SDT for AMD's reference SDT download."
        echo "FPGADRV_SDT_PATH = \"$SDT_PATH\""
        # Bitbake's sstate cache keys downstream consumers (plm-firmware,
        # psm-firmware) only on the recipe's task signature + sysroot file
        # metadata — not on the SDT content itself. So switching from AMD's
        # reference SDT to our XSA-derived one doesn't naturally invalidate
        # those recipes' cached outputs (the plmfw.elf from a previous
        # build with the AMD SDT gets restored). Expose a content hash of
        # the XSA here; bbappends in our meta-user layer add it as a
        # vardep on plm-firmware/psm-firmware so they re-build when the
        # XSA (and therefore the SDT) changes.
        XSA_SHA=$(sha256sum "$XSA" 2>/dev/null | cut -d' ' -f1)
        if [ -n "$XSA_SHA" ]; then
            echo "FPGADRV_XSA_SHA256 = \"$XSA_SHA\""
        fi
    fi
    echo "$MARK_END"
} >> "$CONF_DIR/local.conf"

# NOTE: in the validated-machine flow gen-machineconf is intentionally NOT
# invoked. We use a validated AMD MACHINE (e.g. zynqmp-zcu106-sdt-full) set via
# bsp/<target>/conf/local.conf.append; design-specific PL hardware is conveyed
# through the meta-user device-tree.bbappend overlay (system-user.dtsi).
: "${XSA:?}"

echo "[configure-build] build/conf ready in $BUILDDIR (validated-machine flow)"
