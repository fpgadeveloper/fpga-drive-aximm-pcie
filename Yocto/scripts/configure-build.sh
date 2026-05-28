#!/usr/bin/env bash
#
# Configure a Yocto workspace's build/ directory:
#   1. source edf-init-build-env to create build/ with default local.conf and bblayers.conf
#   2. apply local.conf.append (BSP overrides) and bblayers.conf (meta-user layer)
#      — must happen BEFORE gen-machineconf because that command runs bitbake
#        internally and bitbake reads local.conf at startup
#   3. run gen-machineconf on the project XSA to produce a custom machine .conf
#   4. wire up an optional local sstate-cache mirror
#
# Args:
#   $1 workspace dir   (must contain edf-init-build-env and sources/)
#   $2 TARGET name     (e.g. zcu106_hpc0; used as the gen-machineconf name)
#   $3 BSP dir         (e.g. <repo>/Yocto/bsp/zcu106)
#   $4 XSA file        (absolute path)
#   $5 SSTATE_PATH     (may be empty if no offline cache)
#   $6 SSTATE_ARCH     (e.g. aarch64; only consulted if SSTATE_PATH set)
#   $7 BOOTFILE_PATH   (absolute path to the PL boot artifact:
#                       .bit for zynq/zynqMP (embedded into BOOT.BIN via
#                       xilinx-bootbin) or .pdi for versal (replaces the AMD
#                       reference base PDI). Empty = don't override.)
#   $8 TEMPLATE        (the template name from the Yocto Makefile:
#                       zynqMP / versal / zynq / microblaze. Drives Versal-
#                       specific extra setup like SDT generation from XSA.)

set -euo pipefail

WORKSPACE="$1"
TARGET="$2"
BSP_DIR="$3"
XSA="$4"
SSTATE_PATH="$5"
SSTATE_ARCH="$6"
BOOTFILE_PATH="${7:-}"
TEMPLATE="${8:-}"

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
# meta-user image bbappend is visible to bitbake) -----------------------------
META_USER_DIR="$BSP_DIR/meta-user"
if ! grep -qsF "$META_USER_DIR" "$CONF_DIR/bblayers.conf"; then
    echo "[configure-build] bblayers.conf += $META_USER_DIR"
    {
        echo ""
        echo "# Added by fpga-drive-aximm-pcie Yocto/scripts/configure-build.sh"
        echo "BBLAYERS += \"$META_USER_DIR\""
    } >> "$CONF_DIR/bblayers.conf"
fi

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
# ZynqMP doesn't need this: the FSBL programs the PL via PCAP with a
# self-contained .bit blob, no NPI dispatch, AMD's reference SDT is fine.
SDT_PATH=""
if [ "$TEMPLATE" = "versal" ]; then
    if ! command -v xsct >/dev/null 2>&1; then
        echo "[configure-build] WARNING: xsct not on PATH — Versal SDT generation skipped" >&2
        echo "[configure-build]          (PLM will be built against AMD's reference SDT and is likely to fail)" >&2
    else
        SDT_OUT="$WORKSPACE/sdt"
        rm -rf "$SDT_OUT"
        mkdir -p "$SDT_OUT"
        echo "[configure-build] generating SDT from $XSA via xsct/sdtgen → $SDT_OUT"
        if xsct -eval "sdtgen set_dt_param -dir $SDT_OUT -xsa $XSA; sdtgen generate_sdt" >"$SDT_OUT/sdtgen.log" 2>&1; then
            if [ -f "$SDT_OUT/system-top.dts" ]; then
                SDT_PATH="$SDT_OUT"
                echo "[configure-build]   SDT generated; FPGADRV_SDT_PATH=$SDT_PATH"
            else
                echo "[configure-build] WARNING: sdtgen ran but produced no system-top.dts; see $SDT_OUT/sdtgen.log" >&2
            fi
        else
            echo "[configure-build] WARNING: sdtgen failed; see $SDT_OUT/sdtgen.log" >&2
        fi
    fi
fi

# ---- local.conf: merge BSP overrides + sstate mirror (idempotent) -----------
# gen-machineconf produces conf/machine/<TARGET>.conf but does NOT modify
# local.conf, so we set MACHINE explicitly here to point at it.
LOCAL_APPEND="$BSP_DIR/conf/local.conf.append"
MARK_BEGIN="# >>> fpga-drive-aximm-pcie: BEGIN appended local.conf (do not edit) >>>"
MARK_END="# <<< fpga-drive-aximm-pcie: END appended local.conf <<<"

if grep -qF "$MARK_BEGIN" "$CONF_DIR/local.conf"; then
    sed -i "/^$MARK_BEGIN$/,/^$MARK_END$/d" "$CONF_DIR/local.conf"
fi

{
    echo "$MARK_BEGIN"
    echo "# FPGADRV_TARGET picks a per-target subdir under the BSP's"
    echo "# device-tree/files/ (system-user.dtsi differs per Vivado BD)."
    echo "FPGADRV_TARGET = \"$TARGET\""
    if [ -f "$LOCAL_APPEND" ]; then
        echo "# from $LOCAL_APPEND"
        cat "$LOCAL_APPEND"
    fi
    if [ -n "$SSTATE_PATH" ]; then
        echo ""
        echo "# offline.txt: $SSTATE_PATH"
        # Emit one SSTATE_MIRRORS line per sstate arch subdir that exists.
        # Versal builds need aarch64 (Linux on Cortex-A72) AND microblaze
        # (PMC + PSM firmware multiconfigs); we let the user extract any
        # arch subdir under $SSTATE_PATH and wire them all up.
        mirrors_list=""
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
    fi
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

# NOTE: gen-machineconf is intentionally NOT invoked here. For the EDF flow
# we use a validated AMD MACHINE (e.g. zynqmp-zcu106-sdt-full) set via
# bsp/<target>/conf/local.conf.append. The XSA argument is still consumed by
# this script (so the dependency chain in the Makefile is preserved) but is
# not transformed into a custom machine — design-specific PL hardware is
# instead conveyed through the meta-user device-tree.bbappend overlay
# (system-user.dtsi). This avoids the gap in gen-machineconf 2025.2's
# parse-xsa flow where SDT files are not generated.
: "${XSA:?}"  # unused for now; future XSA-driven steps (pl.dtsi, bitstream) hook in here

echo "[configure-build] build/conf ready in $BUILDDIR"
