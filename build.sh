#!/usr/bin/env bash
#
# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# build.sh -- thin shim: find a working Python 3 and run build.py with all args.
#
# Works under Linux bash and Windows git bash. Order of preference:
#   1. python3 / python on PATH (verified to actually run code -- the Windows
#      "python3" is often a Microsoft Store stub that exists but does nothing)
#   2. the Windows "py -3" launcher
#   3. the Python bundled with the AMD/Xilinx tools (any machine that can
#      build the designs has one)
#
# Usage: ./build.sh <command> [--target <label>]   e.g. ./build.sh xsa --target uzev
#        ./build.sh                                  (overview + valid targets)

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BUILD_SHIM="./build.sh"

works() { "$@" -c 'import sys; sys.exit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; }

for py in python3 python; do
  if works "$py"; then exec "$py" "$DIR/build.py" "$@"; fi
done
if works py -3; then exec py -3 "$DIR/build.py" "$@"; fi

# AMD-bundled Python: <root>/<ver>/tps/{win64,lnx64}/python-*/...
for root in /c/AMDDesignTools /c/Xilinx /c/AMD /d/AMDDesignTools /d/Xilinx \
            /tools/Xilinx /opt/Xilinx /tools/AMDDesignTools "$HOME/Xilinx"; do
  for cand in "$root"/*/tps/win64/python-*/python.exe \
              "$root"/*/tps/lnx64/python-*/bin/python3 \
              "$root"/Vivado/*/tps/lnx64/python-*/bin/python3; do
    if [ -x "$cand" ] && works "$cand"; then exec "$cand" "$DIR/build.py" "$@"; fi
  done
done

echo "ERROR: no working Python 3 found (tried python3, python, py -3, and the" >&2
echo "       AMD-bundled tps python). Install Python 3 and re-run." >&2
exit 1
