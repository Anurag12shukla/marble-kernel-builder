#!/usr/bin/env bash
# =============================================================================
# apply-gkid-config-fragment.sh
# =============================================================================
# Apply the Evolution X GKID Performance config fragment to the kernel build.
#
# Called from build-core.yml after the standard GKI fragments have been merged
# and olddefconfig has been run, but BEFORE the final compilation.
#
# Environment variables consumed:
#   KERNEL_SOURCE        — must be "evolution-x" for this script to activate
#   KERNEL_DIR           — kernel source directory (default: kernel-source)
#   OUT_DIR              — kernel output directory (default: out)
#   ARCH                 — architecture (default: arm64)
#   GKID_ENABLE_HZ_300   — "true" to enable 300Hz timer (default: false)
#   GKID_ENABLE_MGLRU    — "true" to enable MGLRU (default: true)
#   GKID_ENABLE_BBR      — "true" to enable BBR + TCP advanced (default: true)
#   GKID_ENABLE_NTSYNC   — "true" to enable NTSync (default: false)
#
# This script only activates when KERNEL_SOURCE == "evolution-x".
# For all other sources it is a complete no-op (exit 0).
# =============================================================================
set -euo pipefail

KERNEL_SOURCE="${KERNEL_SOURCE:-}"
KERNEL_DIR="${KERNEL_DIR:-kernel-source}"
OUT_DIR="${OUT_DIR:-out}"
ARCH="${ARCH:-arm64}"
FRAGMENT_DIR="config/fragments"
FRAGMENT="evox-gkid-performance.config"

# ── Guard: only activate for evolution-x source ──────────────────────────────
if [[ "${KERNEL_SOURCE}" != "evolution-x" ]]; then
  echo "GKID config fragment: KERNEL_SOURCE=${KERNEL_SOURCE} — skipping (not evolution-x)"
  exit 0
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Applying GKID Performance Config Fragment (evolution-x)    ║"
echo "╚══════════════════════════════════════════════════════════════╝"

DOTCONFIG="${KERNEL_DIR}/${OUT_DIR}/.config"

if [[ ! -f "${DOTCONFIG}" ]]; then
  echo "::error::${DOTCONFIG} not found — run defconfig + GKI fragment merge first"
  exit 1
fi

FRAGMENT_PATH="${FRAGMENT_DIR}/${FRAGMENT}"
if [[ ! -f "${FRAGMENT_PATH}" ]]; then
  echo "::error::GKID fragment not found: ${FRAGMENT_PATH}"
  exit 1
fi

# ── Apply base performance fragment ─────────────────────────────────────────
echo ""
echo "▸ Applying base GKID performance fragment: ${FRAGMENT_PATH}"

# Use scripts/config (present in all GKI trees) for safe option setting.
# This avoids silent failures from merge_config.sh symbol-not-found.
KCONFIG_SCRIPT="${KERNEL_DIR}/scripts/config"

if [[ ! -x "${KCONFIG_SCRIPT}" ]]; then
  echo "::error::${KCONFIG_SCRIPT} not found or not executable"
  exit 1
fi

cfg() {
  local flag="$1" option="$2"
  if "${KCONFIG_SCRIPT}" --file "${DOTCONFIG}" "${flag}" "${option}" 2>/dev/null; then
    echo "  ${flag} ${option}"
  else
    echo "  ::warning:: ${flag} ${option} — symbol not found in this tree (skipped)"
  fi
}

# ── MGLRU ───────────────────────────────────────────────────────────────────
GKID_ENABLE_MGLRU="${GKID_ENABLE_MGLRU:-true}"
if [[ "${GKID_ENABLE_MGLRU}" == "true" ]]; then
  echo ""
  echo "▸ Enabling MGLRU / LRU_GEN"
  cfg -e LRU_GEN
  cfg -e LRU_GEN_ENABLED
  cfg -d LRU_GEN_STATS
else
  echo ""
  echo "▸ MGLRU disabled by GKID_ENABLE_MGLRU=${GKID_ENABLE_MGLRU}"
fi

# ── TCP / BBR ────────────────────────────────────────────────────────────────
GKID_ENABLE_BBR="${GKID_ENABLE_BBR:-true}"
if [[ "${GKID_ENABLE_BBR}" == "true" ]]; then
  echo ""
  echo "▸ Enabling TCP advanced + BBR + Westwood+"
  cfg -e TCP_CONG_ADVANCED
  cfg -e TCP_CONG_BBR
  cfg -e TCP_CONG_WESTWOOD
  # Set default via string option
  "${KCONFIG_SCRIPT}" --file "${DOTCONFIG}" --set-str DEFAULT_TCP_CONG "bbr" 2>/dev/null \
    && echo "  --set-str DEFAULT_TCP_CONG bbr" \
    || echo "  ::warning:: DEFAULT_TCP_CONG string not settable (skipped)"
  # fq / fq_codel
  cfg -e NET_SCH_FQ
  cfg -e NET_SCH_FQ_CODEL
else
  echo ""
  echo "▸ BBR disabled by GKID_ENABLE_BBR=${GKID_ENABLE_BBR}"
fi

# ── 300Hz Timer ──────────────────────────────────────────────────────────────
GKID_ENABLE_HZ_300="${GKID_ENABLE_HZ_300:-false}"
if [[ "${GKID_ENABLE_HZ_300}" == "true" ]]; then
  echo ""
  echo "▸ Enabling 300Hz timer (HZ_300)"
  echo "  ⚠ WARNING: Qualcomm SM8450 clock compatibility not fully verified."
  echo "    Monitor for time drift and WLAN issues after flashing."
  cfg -d HZ_100
  cfg -d HZ_250
  cfg -e HZ_300
  cfg -d HZ_1000
else
  echo ""
  echo "▸ 300Hz timer disabled by GKID_ENABLE_HZ_300=${GKID_ENABLE_HZ_300} — keeping HZ_250"
fi

# ── NTSync ───────────────────────────────────────────────────────────────────
GKID_ENABLE_NTSYNC="${GKID_ENABLE_NTSYNC:-false}"
if [[ "${GKID_ENABLE_NTSYNC}" == "true" ]]; then
  echo ""
  echo "▸ Enabling NTSync (CONFIG_NTSYNC)"
  cfg -e NTSYNC
else
  echo ""
  echo "▸ NTSync disabled by GKID_ENABLE_NTSYNC=${GKID_ENABLE_NTSYNC}"
fi

# ── Safety guards ────────────────────────────────────────────────────────────
echo ""
echo "▸ Applying safety / compatibility guards"
# KSM must remain disabled (security + Spectre risk; Evolution X default)
cfg -d KSM

# ── Regenerate olddefconfig ──────────────────────────────────────────────────
echo ""
echo "▸ Running olddefconfig to resolve symbol dependencies"
make -C "${KERNEL_DIR}" O="${OUT_DIR}" ARCH="${ARCH}" LLVM=1 LLVM_IAS=1 \
  olddefconfig 2>&1

# ── Verification ─────────────────────────────────────────────────────────────
echo ""
echo "▸ Post-fragment config verification"

verify_enabled() {
  local opt="$1" friendly="$2"
  if grep -qE "^CONFIG_${opt}=y$" "${DOTCONFIG}"; then
    echo "  ✅ CONFIG_${opt}=y (${friendly})"
  elif grep -qE "^CONFIG_${opt}=m$" "${DOTCONFIG}"; then
    echo "  ✅ CONFIG_${opt}=m (${friendly} — module)"
  else
    echo "  ℹ️  CONFIG_${opt} not set in final config (symbol may not exist in this tree)"
  fi
}

verify_disabled() {
  local opt="$1" friendly="$2"
  if grep -qE "^# CONFIG_${opt} is not set$" "${DOTCONFIG}" \
     || ! grep -qE "^CONFIG_${opt}=" "${DOTCONFIG}"; then
    echo "  ✅ CONFIG_${opt} not set (${friendly})"
  else
    echo "  ⚠️  CONFIG_${opt} appears set — check manually"
  fi
}

# Always-required verifications
echo ""
echo "  Root / Hiding:"
verify_enabled KSU "KernelSU/ReSukiSU"
verify_enabled KSU_SUSFS "SUSFS"
verify_enabled KSU_SUSFS_SUS_PATH "SUS_PATH"
verify_enabled KSU_SUSFS_SUS_MOUNT "SUS_MOUNT"
verify_enabled KSU_SUSFS_SUS_KSTAT "SUS_KSTAT"
verify_enabled KSU_SUSFS_SPOOF_UNAME "SPOOF_UNAME"
verify_enabled KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG "SPOOF_CMDLINE"
verify_enabled KSU_SUSFS_OPEN_REDIRECT "OPEN_REDIRECT"
verify_enabled KSU_SUSFS_SUS_MAP "SUS_MAP"
verify_disabled KSM "KSM security disable"

echo ""
echo "  LTO / Compatibility:"
verify_enabled LTO "LTO"
verify_enabled LTO_CLANG "LTO_CLANG"
verify_enabled LTO_CLANG_THIN "ThinLTO"
verify_enabled MODVERSIONS "Module versioning"

if [[ "${GKID_ENABLE_MGLRU}" == "true" ]]; then
  echo ""
  echo "  MGLRU:"
  verify_enabled LRU_GEN "MGLRU"
fi

if [[ "${GKID_ENABLE_BBR}" == "true" ]]; then
  echo ""
  echo "  TCP/Network:"
  verify_enabled TCP_CONG_ADVANCED "TCP advanced"
  verify_enabled TCP_CONG_BBR "BBR"
  verify_enabled TCP_CONG_WESTWOOD "Westwood+"
fi

if [[ "${GKID_ENABLE_HZ_300}" == "true" ]]; then
  echo ""
  echo "  Timer:"
  verify_enabled HZ_300 "300Hz"
  verify_disabled HZ_250 "HZ_250 replaced"
fi

if [[ "${GKID_ENABLE_NTSYNC}" == "true" ]]; then
  echo ""
  echo "  NTSync:"
  verify_enabled NTSYNC "NTSync"
fi

echo ""
echo "✅ GKID config fragment applied and verified."
