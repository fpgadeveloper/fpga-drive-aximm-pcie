#!/usr/bin/env bash
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

# bitbake puts artifacts under deploy/images/<MACHINE>/ — exactly one
# MACHINE per build for our flow, so just glob it.
MACHINE_DIR=$(find "$DEPLOY" -mindepth 1 -maxdepth 1 -type d | head -n1)
if [ -z "$MACHINE_DIR" ] || [ ! -d "$MACHINE_DIR" ]; then
    echo "ERROR: no machine subdir under $DEPLOY" >&2
    exit 1
fi

mkdir -p "$DEST"

# Helper: copy a file from MACHINE_DIR into DEST under a canonical name.
# Resolves symlinks so we get the file content, not a dangling link.
gather() {
    local pattern="$1"
    local canonical="$2"
    # Glob the pattern relative to MACHINE_DIR and pick the newest match.
    local match
    match=$(cd "$MACHINE_DIR" && ls -t -1 $pattern 2>/dev/null | head -n1 || true)
    if [ -n "$match" ] && [ -e "$MACHINE_DIR/$match" ]; then
        cp -fL "$MACHINE_DIR/$match" "$DEST/$canonical"
        echo "[package-output]   $canonical  (from $match)"
    else
        echo "[package-output]   skipped $canonical  (no match for $pattern)"
    fi
}

echo "[package-output] gathering from $MACHINE_DIR"

# Core boot artifacts the user flashes to SD card.
gather "BOOT-*-*.bin"                       "BOOT.BIN"
gather "boot.scr"                           "boot.scr"
gather "Image"                              "Image"
gather "*.dtb"                              "system.dtb"
gather "u-boot.elf*"                        "u-boot.elf"

# Root filesystem in multiple forms.
gather "*-disk-image-*.rootfs-*.wic.xz"     "rootfs.wic.xz"
gather "*-disk-image-*.rootfs-*.tar.gz"     "rootfs.tar.gz"

# A bmap for fast `bmaptool` flashing if produced.
gather "*-disk-image-*.rootfs-*.wic.bmap"   "rootfs.wic.bmap"

echo "[package-output] gathered images into $DEST"
ls -la "$DEST"
