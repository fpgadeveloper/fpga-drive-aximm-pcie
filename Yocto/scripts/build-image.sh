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

# Host-tool workarounds (today: a tar that BitBake's pseudo cannot fake-root).
# A no-op on a host that does not need them; see Yocto/scripts/hostfix.sh.
# Tolerates the file being absent, so a repo that has only part of the engine
# deployed still builds exactly as it did before.
HOSTFIX_SH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/hostfix.sh"
if [ -f "$HOSTFIX_SH" ]; then
    # shellcheck disable=SC1090
    source "$HOSTFIX_SH"
else
    hostfix_init() { :; }
    hostfix_late() { :; }
fi
hostfix_init "$WORKSPACE"

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

# Last resort for a host whose own tar is unusable and that has no other:
# let bitbake build tar-native and use that. No-op otherwise.
hostfix_late "$WORKSPACE"

echo "[build-image] bitbake $RECIPE  (BB_NUMBER_THREADS=$JOBS)"
bitbake "$RECIPE"
