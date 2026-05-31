#!/usr/bin/env bash
#
# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Run bitbake in a configured Yocto workspace.
#
# Args:
#   $1 workspace dir
#   $2 image recipe (e.g. petalinux-image-minimal)
#   $3 JOBS / parallel make threads

set -euo pipefail

WORKSPACE="$1"
RECIPE="$2"
JOBS="$3"

cd "$WORKSPACE"
# AMD's edf-init-build-env references $ZSH_NAME without quoting; relax
# `set -u` while sourcing it. oe-init-build-env (called from it) treats the
# first positional arg as the builddir — pass it explicitly to avoid grabbing
# our own positional args.
set +u
set -- build
# shellcheck disable=SC1091
source ./edf-init-build-env build
set -u

export BB_NUMBER_THREADS="$JOBS"
export PARALLEL_MAKE="-j$JOBS"

echo "[build-image] bitbake $RECIPE  (BB_NUMBER_THREADS=$JOBS)"
bitbake "$RECIPE"
