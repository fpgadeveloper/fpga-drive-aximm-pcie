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
#   $7 BITSTREAM_PATH  (absolute path to .bit file; embedded into BOOT.BIN)

set -euo pipefail

WORKSPACE="$1"
TARGET="$2"
BSP_DIR="$3"
XSA="$4"
SSTATE_PATH="$5"
SSTATE_ARCH="$6"
BITSTREAM_PATH="${7:-}"

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
    if [ -f "$LOCAL_APPEND" ]; then
        echo "# from $LOCAL_APPEND"
        cat "$LOCAL_APPEND"
    fi
    if [ -n "$SSTATE_PATH" ]; then
        echo ""
        echo "# offline.txt: $SSTATE_PATH"
        echo "SSTATE_MIRRORS ?= \"file://.* file://$SSTATE_PATH/$SSTATE_ARCH/PATH\""
        if [ -d "$SSTATE_PATH/downloads" ]; then
            echo "SOURCE_MIRROR_URL ?= \"file://$SSTATE_PATH/downloads/\""
            echo "INHERIT += \"own-mirrors\""
        fi
    fi
    if [ -n "$BITSTREAM_PATH" ] && [ -f "$BITSTREAM_PATH" ]; then
        echo ""
        echo "# Embed our Vivado-built PL bitstream into BOOT.BIN. The default"
        echo "# BIF_BITSTREAM_ATTR is empty for zynqmp (no bitstream); setting"
        echo "# it to \"bitstream\" pulls in virtual/bitstream, which the recipe"
        echo "# below satisfies from BITSTREAM_PATH."
        echo "BIF_BITSTREAM_ATTR = \"bitstream\""
        echo "BITSTREAM_PATH = \"$BITSTREAM_PATH\""
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
