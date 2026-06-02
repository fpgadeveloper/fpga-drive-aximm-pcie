#!/usr/bin/env bash
#
# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Gather bitbake's deploy outputs into <WORKSPACE>/images/linux/ so the
# top-level packaging stage (../Makefile) can find them in the same
# canonical location used by PetaLinux builds.
#
# Args:
#   $1 workspace dir (e.g. ../zcu106_hpc0)
#   $2 destination images dir (e.g. ../zcu106_hpc0/images/linux)

set -euo pipefail

WORKSPACE="$1"
DEST="$2"

DEPLOY="$WORKSPACE/build/tmp/deploy/images"
if [ ! -d "$DEPLOY" ]; then
    echo "ERROR: bitbake deploy dir not found at $DEPLOY" >&2
    exit 1
fi

# bitbake puts artifacts under deploy/images/<MACHINE>/. For Versal,
# BBMULTICONFIG produces several MACHINE subdirs (the main one plus
# -microblaze-pmc / -microblaze-psm / -cortexr5-0-freertos for the PLM,
# PSM, and RPU sub-builds). Pick the one that has the rootfs image —
# only the main MACHINE produces edf-linux-disk-image outputs.
MACHINE_DIR=""
for d in "$DEPLOY"/*/; do
    if compgen -G "${d}*-disk-image-*.rootfs-*.wic.xz" > /dev/null 2>&1 \
       || compgen -G "${d}*-disk-image-*.rootfs-*.tar.gz" > /dev/null 2>&1; then
        MACHINE_DIR="${d%/}"
        break
    fi
done
if [ -z "$MACHINE_DIR" ] || [ ! -d "$MACHINE_DIR" ]; then
    echo "ERROR: no MACHINE deploy dir under $DEPLOY contains a rootfs image" >&2
    exit 1
fi

mkdir -p "$DEST"

# Helper: copy a file from MACHINE_DIR into DEST under a canonical name.
# Resolves symlinks so we get the file content, not a dangling link.
# If $3 (exclude_substring) is given, candidates containing it are skipped —
# used to dodge the Versal `BOOT-*-*_bh.bin` boot-header sidecar.
gather() {
    local pattern="$1"
    local canonical="$2"
    local exclude="${3:-}"
    local match
    if [ -n "$exclude" ]; then
        match=$(cd "$MACHINE_DIR" && ls -t -1 $pattern 2>/dev/null | grep -v -- "$exclude" | head -n1 || true)
    else
        match=$(cd "$MACHINE_DIR" && ls -t -1 $pattern 2>/dev/null | head -n1 || true)
    fi
    if [ -n "$match" ] && [ -e "$MACHINE_DIR/$match" ]; then
        cp -fL "$MACHINE_DIR/$match" "$DEST/$canonical"
        echo "[package-output]   $canonical  (from $match)"
    else
        echo "[package-output]   skipped $canonical  (no match for $pattern)"
    fi
}

echo "[package-output] gathering from $MACHINE_DIR"

# Core boot artifacts the user flashes to SD card.
# Versal deploys both BOOT-*-*.bin (full BOOT.BIN) and BOOT-*-*_bh.bin
# (boot header sidecar, ~4 KB) — exclude the boot header.
gather "BOOT-*-*.bin"                       "BOOT.BIN"      "_bh"
gather "boot.scr"                           "boot.scr"
# Kernel image: zynqMP/Versal deploy a raw `Image`; Zynq-7000 (zynq) deploys a
# u-boot-wrapped `uImage`. Gather whichever this machine produced.
if [ -e "$MACHINE_DIR/Image" ]; then
    gather "Image"                          "Image"
else
    gather "uImage"                         "uImage"
fi
gather "*.dtb"                              "system.dtb"
gather "u-boot.elf*"                        "u-boot.elf"

# Root filesystem in multiple forms.
gather "*-disk-image-*.rootfs-*.wic.xz"     "rootfs.wic.xz"
gather "*-disk-image-*.rootfs-*.tar.gz"     "rootfs.tar.gz"

# A bmap for fast `bmaptool` flashing if produced.
gather "*-disk-image-*.rootfs-*.wic.bmap"   "rootfs.wic.bmap"

echo "[package-output] gathered images into $DEST"
ls -la "$DEST"
