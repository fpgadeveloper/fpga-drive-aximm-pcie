#!/usr/bin/env bash
#
# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# hostfix.sh -- work around host tools that break BitBake's fakeroot (pseudo).
#
# Today it handles exactly one problem, described in full below: a host `tar`
# that opens directories with the openat2(2) syscall, which the pseudo shipped
# by this release cannot intercept. On a host without the problem this script
# does nothing at all -- it finds the host tar good and returns before touching
# the workspace, the PATH or bitbake.
#
# THE PROBLEM
#   Distributions that carry the security fix for CVE-2025-45582 (Ubuntu's
#   tar 1.35+dfsg-3ubuntu0.x, among others) resolve every path component during
#   extraction with
#       openat2(AT_FDCWD, "var/", {... resolve=RESOLVE_BENEATH}, 24) = 4
#   instead of openat(2). pseudo is an LD_PRELOAD library: it can only intercept
#   libc calls, and openat2 has no libc wrapper -- tar issues the raw syscall.
#   pseudo therefore never learns which directory that file descriptor refers to,
#   and the next *at() call on it fails:
#       got *at() syscall for unknown directory, fd 4
#       unknown base path for fd 4, path volatile
#       couldn't allocate absolute path for 'volatile'.
#       tar: ./var/volatile: Cannot mkdir: Bad address
#   Every fakeroot task that unpacks a tar archive -- do_package and the sstate
#   unpack that feeds it -- fails, so the image cannot be built. It has nothing
#   to do with the tar *version*: it is which syscalls that particular build uses.
#
# THE FIX WE APPLY
#   Give bitbake a tar that pseudo does handle, by putting one first on PATH
#   before bitbake resolves its host tools. Any tar that was not built against
#   the patched distro sources works -- including the one bitbake itself builds
#   (tar-native), which is why this needs no PetaLinux install and no download.
#   OpenEmbedded marks this CVE "disputed" for its own tar recipe
#   (CVE_STATUS[CVE-2025-45582] in oe-core master) and ships no such patch, so
#   an OE-built tar is good by construction.
#
# THE FIX UPSTREAM APPLIED, AND WHY WE DO NOT
#   pseudo itself was fixed: commit 472c8977e023 "ports/linux/pseudo_wrappers:
#   Avoid openat2 usage via syscall" (2026-01-12, first released in pseudo
#   1.9.3) makes the syscall() interposer return ENOSYS for SYS_openat2, so tar
#   falls back to plain openat(), which pseudo has always wrapped. A real
#   openat2 wrapper followed in 1.9.4. oe-core carries it from scarthgap 5.0.16
#   on; this release is pinned to pseudo 1.9.0+git (SRCREV 28dcefb809ce), which
#   predates all of it.
#   Bumping that SRCREV from a layer fragment would be the root-cause fix, but
#   it changes pseudo-native's signature, and pseudo-native sits under every
#   fakeroot task -- so it costs a large shared-state miss for every customer on
#   every host, including the ones that never had the problem. Swapping one host
#   binary changes no metadata, no signature and no shared state. If you do want
#   the root-cause fix, scarthgap's pseudo 1.9.8 (SRCREV
#   823895ba708c63f6ae4dcbfc266210f26c02c698) is the closest match; note the
#   recipe's 0001-configure-Prune-PIE-flags.patch and glibc238.patch were
#   dropped upstream past 1.9.0 and would have to go with it.
#
# WHY THE PATH ALONE IS NOT ENOUGH
#   BitBake does not give tasks the caller's PATH. Its sanity check resolves
#   every tool in HOSTTOOLS once and symlinks it into build/tmp/hosttools/, and
#   it only re-resolves a tool whose symlink is missing. A workspace that ever
#   ran a build without the fix therefore keeps using the bad tar no matter what
#   PATH later builds are given. This script removes that one stale symlink so
#   the next bitbake re-resolves it.
#
# USAGE
#   Source it, then call the two functions in order:
#
#       source "$(dirname "$0")/hostfix.sh"
#       hostfix_init <workspace>          # before bitbake: probe, fix if needed
#       ...
#       hostfix_late <workspace>          # inside a sourced bitbake env, when
#                                         # hostfix_init could not find a tar
#
#   hostfix_init is safe to call any number of times and from any shell. It is a
#   no-op once the PATH is already fixed.
#
#   HOSTFIX_DISABLE=1 in the environment turns the whole thing off.

# ---------------------------------------------------------------------------
# probe: is <tar> usable under pseudo?
#
# Three backends, most conclusive first; the first one that can answer, answers.
#   1. pseudo  -- the real thing: extract a two-level archive under the very
#                 pseudo this workspace uses and see whether the nested member
#                 arrived. Used whenever a pseudo has already been built here.
#   2. strace  -- watch for an openat2() during the same extraction.
#   3. objdump -- look for the openat2 syscall number (437 = 0x1b5) as an
#                 immediate in the binary. x86-64 only, which is the only host
#                 architecture the AMD tools support anyway.
# Returns 0 = good, 1 = bad, 2 = could not tell.
# ---------------------------------------------------------------------------
hostfix_probe_tar() {
    local tar_bin="$1" ws="${2:-}"
    [ -n "$tar_bin" ] && [ -x "$tar_bin" ] || return 2

    local tmp; tmp="$(mktemp -d)" || return 2
    # A nested directory is what fails: tar opens "var/" to create "volatile"
    # inside it, and it is that descriptor pseudo cannot resolve.
    mkdir -p "$tmp/src/var/volatile" "$tmp/out" "$tmp/state"
    : > "$tmp/src/var/volatile/probe"
    if ! "$tar_bin" cf "$tmp/probe.tar" -C "$tmp/src" . >/dev/null 2>&1; then
        rm -rf "$tmp"; return 2
    fi

    local rc=2 pseudo_bin=""
    if [ -n "$ws" ]; then
        pseudo_bin="$(find "$ws/build/tmp/sysroots-components/x86_64/pseudo-native" \
                        -name pseudo -type f -perm -u+x 2>/dev/null | head -1)"
    fi
    if [ -n "$pseudo_bin" ] && [ -x "$pseudo_bin" ]; then
        # The verdict is the artifact, not the message: a nested member that
        # survived means pseudo resolved every descriptor tar handed it.
        (
            PSEUDO_PREFIX="$(dirname "$(dirname "$pseudo_bin")")"
            PSEUDO_LOCALSTATEDIR="$tmp/state"
            export PSEUDO_PREFIX PSEUDO_LOCALSTATEDIR
            "$pseudo_bin" -- "$tar_bin" xf "$tmp/probe.tar" -C "$tmp/out"
        ) >/dev/null 2>&1 || true
        if [ -f "$tmp/out/var/volatile/probe" ]; then rc=0; else rc=1; fi
        rm -rf "$tmp"; return $rc
    fi

    if command -v strace >/dev/null 2>&1; then
        if strace -f -e trace=openat2 -o "$tmp/trace" \
                  "$tar_bin" xf "$tmp/probe.tar" -C "$tmp/out" >/dev/null 2>&1; then
            if grep -q 'openat2(' "$tmp/trace" 2>/dev/null; then rc=1; else rc=0; fi
            rm -rf "$tmp"; return $rc
        fi
    fi

    if command -v objdump >/dev/null 2>&1 \
       && [ "$(uname -m 2>/dev/null)" = "x86_64" ]; then
        if objdump -d "$tar_bin" 2>/dev/null | grep -q '\$0x1b5'; then rc=1; else rc=0; fi
    fi
    rm -rf "$tmp"
    return $rc
}

# ---------------------------------------------------------------------------
# Candidate replacement tars, in order of preference. None is required to
# exist; each is verified with the same probe before it is used.
# ---------------------------------------------------------------------------
hostfix_candidate_tars() {
    local ws="$1"
    {
        # 1. a tar bitbake already built in THIS workspace. oe-core's tar recipe
        #    sets NATIVE_PACKAGE_PATH_SUFFIX = "/${PN}", so the native binary is
        #    at .../usr/bin/tar-native/tar, not .../usr/bin/tar.
        find "$ws/build/tmp/sysroots-components/x86_64/tar-native/usr/bin" \
             -name tar -type f 2>/dev/null
        find "$ws/build/tmp/work/x86_64-linux/tar-native" \
             -path '*/recipe-sysroot-native/usr/bin/*' -name tar -type f 2>/dev/null
        # 2. a Yocto buildtools / eSDK native sysroot the user already sourced
        if [ -n "${OECORE_NATIVE_SYSROOT:-}" ]; then
            echo "$OECORE_NATIVE_SYSROOT/usr/bin/tar"
        fi
        ls -1 /opt/poky*/*/sysroots/x86_64-*/usr/bin/tar 2>/dev/null
        # 3. PetaLinux, when this host happens to have it (never required)
        if [ -n "${PETALINUX:-}" ]; then
            echo "$PETALINUX/sysroots/x86_64-petalinux-linux/usr/bin/tar"
        fi
        ls -1 "$HOME"/petalinux/*/sysroots/x86_64-petalinux-linux/usr/bin/tar \
              /opt/petalinux/*/sysroots/x86_64-petalinux-linux/usr/bin/tar \
              /tools/*/petalinux/*/sysroots/x86_64-petalinux-linux/usr/bin/tar 2>/dev/null
    } 2>/dev/null || true
}

hostfix_install() {
    local ws="$1" good="$2"
    local dir="$ws/hostfix/bin"
    mkdir -p "$dir"
    ln -sf "$good" "$dir/tar"
    case ":$PATH:" in
        *":$dir:"*) ;;
        *) PATH="$dir:$PATH"; export PATH ;;
    esac
    # Bust the one cached HOSTTOOLS symlink, so the next bitbake re-resolves
    # tar from the PATH we just fixed. Removing only this link leaves the rest
    # of the (expensive to rebuild) hosttools dir alone.
    local cached="$ws/build/tmp/hosttools/tar"
    if [ -L "$cached" ] && [ "$(readlink -f "$cached")" != "$(readlink -f "$dir/tar")" ]; then
        rm -f "$cached"
        echo "[hostfix] dropped the stale build/tmp/hosttools/tar symlink"
    fi
    echo "[hostfix] using tar: $good"
    echo "[hostfix]   via $dir/tar (first on PATH)"
}

hostfix_no_tar_found() {
    cat >&2 <<'EOF'
[hostfix] ============================================================
[hostfix] WARNING: this host's tar breaks BitBake's fakeroot (pseudo).
[hostfix]
[hostfix] Its tar opens directories with the openat2() syscall, which
[hostfix] the pseudo of this release cannot intercept, so fakeroot
[hostfix] tasks fail with:
[hostfix]     tar: ./var/volatile: Cannot mkdir: Bad address
[hostfix]
[hostfix] No usable replacement tar was found on this machine and one
[hostfix] could not be built. The build will very likely fail in
[hostfix] do_package. Any ONE of these fixes it:
[hostfix]
[hostfix]  * Install the Yocto buildtools tarball and source its
[hostfix]    environment-setup script before building
[hostfix]    (x86_64-buildtools-nativesdk-standalone-5.0.x.sh from
[hostfix]    downloads.yoctoproject.org -- it ships a usable tar).
[hostfix]  * Put any tar NOT built from the patched distro sources
[hostfix]    first on PATH (a PetaLinux install ships one at
[hostfix]    <petalinux>/sysroots/x86_64-petalinux-linux/usr/bin/tar).
[hostfix]  * Build on a host whose tar does not carry the change.
[hostfix]
[hostfix] Then delete <workspace>/build/tmp/hosttools/tar, or bitbake
[hostfix] will keep using the symlink it cached on the first run.
[hostfix]
[hostfix] Set HOSTFIX_DISABLE=1 to silence this check.
[hostfix] ============================================================
EOF
}

# ---------------------------------------------------------------------------
# hostfix_init <workspace>
#   Probe the host tar and, when it is bad, put a good one first on PATH.
#   Sets HOSTFIX_TAR_NEEDED=1 when it knows the tar is bad but found no
#   replacement without bitbake -- hostfix_late can then build one.
# ---------------------------------------------------------------------------
hostfix_init() {
    local ws="${1:-}"
    HOSTFIX_TAR_NEEDED=0
    if [ "${HOSTFIX_DISABLE:-0}" = "1" ]; then return 0; fi
    if [ -z "$ws" ]; then return 0; fi

    local host_tar rc=0
    host_tar="$(command -v tar 2>/dev/null || true)"
    # Never let the probe's verdict trip `set -e` in the caller's script.
    hostfix_probe_tar "$host_tar" "$ws" || rc=$?
    case $rc in
        0) return 0 ;;                       # good tar: do nothing at all
        2) echo "[hostfix] could not determine whether '$host_tar' works under" \
                "pseudo (no pseudo built yet, no strace, no objdump); continuing." >&2
           echo "[hostfix] If do_package fails with 'Cannot mkdir: Bad address'," \
                "see the Yocto page of the docs." >&2
           return 0 ;;
    esac

    echo "[hostfix] host tar ($host_tar) cannot be used under pseudo" \
         "(openat2); looking for a replacement"
    local cand
    while read -r cand; do
        [ -n "$cand" ] && [ -x "$cand" ] || continue
        if hostfix_probe_tar "$cand" "$ws"; then
            hostfix_install "$ws" "$cand"
            return 0
        fi
    done <<EOF
$(hostfix_candidate_tars "$ws")
EOF

    HOSTFIX_TAR_NEEDED=1
    return 0
}

# ---------------------------------------------------------------------------
# hostfix_late <workspace>
#   Last resort, called from inside a shell that has sourced the workspace's
#   build environment: let bitbake build its own tar and use that. It is a
#   native recipe, so nothing in its dependency chain runs a fakeroot task --
#   it builds fine on a host whose tar is broken under pseudo.
#
#   The target is tar-replacement-native, NOT tar-native: `tar-native` is in
#   oe-core's ASSUME_PROVIDED, so asking for it succeeds without building
#   anything. oe-core's own tar recipe carries
#   PROVIDES:append:class-native = " tar-replacement-native" for exactly this
#   purpose (image_types.bbclass depends on it to get a reproducible tar).
# ---------------------------------------------------------------------------
hostfix_late() {
    local ws="${1:-}"
    if [ "${HOSTFIX_TAR_NEEDED:-0}" != "1" ]; then return 0; fi
    if [ -z "$ws" ]; then return 0; fi
    if ! command -v bitbake >/dev/null 2>&1; then hostfix_no_tar_found; return 0; fi

    echo "[hostfix] no usable tar on this host -- building one" \
         "(bitbake tar-replacement-native)"
    if ! bitbake tar-replacement-native; then
        hostfix_no_tar_found
        return 0
    fi
    local cand
    while read -r cand; do
        [ -n "$cand" ] && [ -x "$cand" ] || continue
        if hostfix_probe_tar "$cand" "$ws"; then
            hostfix_install "$ws" "$cand"
            HOSTFIX_TAR_NEEDED=0
            return 0
        fi
    done <<EOF
$(hostfix_candidate_tars "$ws")
EOF
    hostfix_no_tar_found
    return 0
}

# Running it directly reports what it would do, and changes nothing but the
# workspace's hostfix/bin symlink:  ./hostfix.sh <workspace>
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    set -uo pipefail
    hostfix_init "${1:-}"
    if [ "${HOSTFIX_TAR_NEEDED:-0}" = "1" ]; then
        echo "[hostfix] host tar is bad and no replacement was found without bitbake;"
        echo "[hostfix] the Yocto stage will try 'bitbake tar-native'."
    fi
fi
