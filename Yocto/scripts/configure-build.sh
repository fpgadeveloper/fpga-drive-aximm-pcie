#!/usr/bin/env bash
#
# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Configure a Yocto workspace's build/ directory using AMD's recommended
# gen-machineconf "parse-sdt" flow (the only supported flow):
#
#   1. source edf-init-build-env to create build/ with default conf
#   2. add our meta-user layer to bblayers.conf
#   3. generate a System Device Tree (SDT) from the project XSA via xsct/sdtgen
#   4. run `gen-machineconf parse-sdt` on the SDT to generate a *custom*
#      MACHINE (fpgadrv-<target>) whose device tree — PS and PL — is derived
#      directly from the hardware. Changes a customer makes to the PS in Vivado
#      therefore flow straight through XSA -> SDT -> machine.conf -> device tree.
#   5. set MACHINE to the generated name and apply BSP overrides + sstate.
#
# The flow is SoC-agnostic: gen-machineconf auto-detects the SoC family from the
# SDT and auto-wires the boot artifact (the .bit/.pdi that sdtgen extracts from
# the XSA into the SDT dir) — no per-template handling is required here. Because
# no PL overlay is requested, fpga-overlay is left out of MACHINE_FEATURES and
# xilinx-bootbin embeds the bitstream into BOOT.BIN (FSBL programs the PL at
# boot, before Linux/PCIe come up).
#
# Args:
#   $1 workspace dir   (must contain edf-init-build-env and sources/)
#   $2 TARGET name     (e.g. zcu104; used as the gen-machineconf machine suffix)
#   $3 BSP dir         (e.g. <repo>/Yocto/bsp/zcu104)
#   $4 XSA file        (absolute path)
#   $5 SSTATE_PATH     (may be empty if no offline cache)
#   $6 BD_NAME         (block-design name from the Makefile; used as the
#                       machine-name prefix so it is repo-specific)
#   $7 PORT_CFG_DIR    (optional per-target overlay layer dir, e.g.
#                       <repo>/Yocto/bsp/port-configs/ports-0123; empty = none)

set -euo pipefail

WORKSPACE="$1"
TARGET="$2"
BSP_DIR="$3"
XSA="$4"
SSTATE_PATH="${5:-}"
BD_NAME="${6:-design}"
PORT_CFG_DIR="${7:-}"

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
        echo "# Added by Yocto/scripts/configure-build.sh"
        echo "BBLAYERS += \"$META_USER_DIR\""
    } >> "$CONF_DIR/bblayers.conf"
fi

# Optional per-target overlay layer (e.g. an Ethernet port-config layer that
# adds a port-config.dtsi to the device-tree recipe). Added alongside the board
# meta-user layer so both bbappends apply. No-op when PORT_CFG_DIR is empty or
# has no meta-user — keeps this script universal for repos with no overlays.
if [ -n "$PORT_CFG_DIR" ] && [ -d "$PORT_CFG_DIR/meta-user" ]; then
    OVERLAY_DIR="$PORT_CFG_DIR/meta-user"
    if ! grep -qsF "$OVERLAY_DIR" "$CONF_DIR/bblayers.conf"; then
        echo "[configure-build] bblayers.conf += $OVERLAY_DIR (overlay)"
        {
            echo ""
            echo "# Overlay layer added by Yocto/scripts/configure-build.sh"
            echo "BBLAYERS += \"$OVERLAY_DIR\""
        } >> "$CONF_DIR/bblayers.conf"
    fi
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
        echo "[configure-build] ERROR: xsct not on PATH — source the Vitis settings64.sh before make" >&2
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
    echo "[configure-build] ERROR: sdtgen failed; see $sdt_out/sdtgen.log" >&2
    return 1
}

# ---- 1. SDT from XSA --------------------------------------------------------
if ! generate_sdt; then
    echo "ERROR: SDT generation failed; cannot configure the build." >&2
    exit 1
fi

# ---- 2. gen-machineconf parse-sdt -> custom MACHINE -------------------------
# bitbake is available (we sourced edf-init-build-env) so the tool builds its
# own native helpers (kconfig-frontends-native, esw-conf-native, lopper) and
# fetches/processes the SDT itself.
MACHINE_NAME="${BD_NAME}-${TARGET}"
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

# ---- 3. local.conf: select the generated MACHINE + BSP overrides + sstate ---
LOCAL_APPEND="$BSP_DIR/conf/local.conf.append"
MARK_BEGIN="# >>> EDF Yocto build: BEGIN appended local.conf (do not edit) >>>"
MARK_END="# <<< EDF Yocto build: END appended local.conf <<<"

# Strip any previously appended block so this script is idempotent.
if grep -qF "$MARK_BEGIN" "$CONF_DIR/local.conf"; then
    sed -i "/^$MARK_BEGIN$/,/^$MARK_END$/d" "$CONF_DIR/local.conf"
fi

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

echo "[configure-build] build/conf ready in $BUILDDIR (MACHINE=$MACHINE_NAME)"
