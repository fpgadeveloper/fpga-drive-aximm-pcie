#!/usr/bin/env bash
#
# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Initialize a per-target Yocto workspace using Google's `repo` tool against
# the AMD yocto-manifests repository. Idempotent: re-running on an already-
# initialized workspace is a no-op (no resync).
#
# Args:
#   $1 workspace dir (e.g. ../zcu106_hpc0)
#   $2 manifest URL (e.g. https://github.com/Xilinx/yocto-manifests.git)
#   $3 manifest branch (e.g. rel-v2025.2)
#   $4 manifest file  (e.g. default-edf.xml)

set -euo pipefail

WORKSPACE="$1"
MANIFEST_URL="$2"
MANIFEST_BRANCH="$3"
MANIFEST_FILE="$4"

if ! command -v repo >/dev/null 2>&1; then
    echo "ERROR: Google 'repo' tool not found on PATH." >&2
    echo "Install with:" >&2
    echo "  sudo apt-get install repo            # Debian/Ubuntu" >&2
    echo "  # or download from https://gerrit.googlesource.com/git-repo/" >&2
    exit 1
fi

mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

if [ ! -d .repo ]; then
    echo "[init-workspace] repo init -b $MANIFEST_BRANCH -m $MANIFEST_FILE"
    repo init -u "$MANIFEST_URL" -b "$MANIFEST_BRANCH" -m "$MANIFEST_FILE"
fi

# The EDF manifest produces a top-level setup script named edf-init-build-env.
# (The PetaLinux manifest names it setupsdk — they are not interchangeable.)
SETUP=edf-init-build-env

if [ ! -f "$SETUP" ]; then
    echo "[init-workspace] repo sync"
    repo sync
fi

if [ ! -f "$SETUP" ]; then
    echo "ERROR: repo sync completed but $SETUP was not produced in $WORKSPACE" >&2
    echo "Verify the manifest branch '$MANIFEST_BRANCH' and file '$MANIFEST_FILE' are correct." >&2
    exit 1
fi

echo "[init-workspace] workspace ready at $WORKSPACE"
