#!/usr/bin/env bash
# =============================================================================
# validate-nethunter-config.sh
# CI validation script for the NetHunter kernel configuration
# =============================================================================
# Usage: validate-nethunter-config.sh <path-to-.config>
# Exit 0 = all mandatory checks pass
# Exit 1 = one or more mandatory checks fail
# =============================================================================
set -euo pipefail

CONFIG_FILE="${1:-out/.config}"
[[ -f "${CONFIG_FILE}" ]] || { echo "::error::Config file not found: ${CONFIG_FILE}"; exit 1; }

PASS=0
FAIL=0
WARN=0

STEP_SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

pass() { echo "  ✅ PASS  $*"; ((PASS++)); }
fail() { echo "  ❌ FAIL  $*"; echo "::error::CONFIG CHECK FAILED: $*"; ((FAIL++)); }
warn() { echo "  ⚠️  WARN  $*"; echo "::warning::CONFIG CHECK WARN: $*"; ((WARN++)); }
section() { echo ""; echo "── $* ──"; }

config_is() {
    local key="$1" val="$2"
    grep -q "^${key}=${val}$" "${CONFIG_FILE}"
}
config_set() { config_is "$1" "y" || config_is "$1" "m"; }
config_not_set() { grep -q "^# ${1} is not set$" "${CONFIG_FILE}" || ! grep -q "^${1}=" "${CONFIG_FILE}"; }
config_val() { grep "^${1}=" "${CONFIG_FILE}" | cut -d= -f2- || echo "NOT_SET"; }

echo "======================================================================"
echo "  NetHunter Kernel Config Validation"
echo "  Config: ${CONFIG_FILE}"
echo "======================================================================"

# ── §23 KERNEL IDENTITY ───────────────────────────────────────────────────────
section "Kernel Identity"
config_set CONFIG_ARM64 && pass "ARM64 architecture" || fail "ARM64 architecture missing"
config_set CONFIG_MODULES && pass "Loadable module support" || fail "Module support missing"
config_set CONFIG_MODULE_UNLOAD && pass "Module unloading" || warn "Module unloading not set"
config_set CONFIG_MODVERSIONS && pass "MODVERSIONS (vendor compat)" || fail "MODVERSIONS missing — vendor modules will break"

# ── §23 ROOT MANAGER ─────────────────────────────────────────────────────────
section "Root Manager (ReSukiSU + SUSFS)"
config_set CONFIG_KSU && pass "CONFIG_KSU enabled" || fail "CONFIG_KSU missing — ReSukiSU not present"
# SUSFS options — check a representative set
for opt in CONFIG_KSU_SUSFS CONFIG_KSU_SUSFS_SUS_PATH CONFIG_KSU_SUSFS_SUS_MOUNT \
           CONFIG_KSU_SUSFS_TRY_UMOUNT CONFIG_KSU_SUSFS_SPOOF_UNAME; do
    config_set "${opt}" && pass "${opt}" || warn "${opt} not set (may depend on ReSukiSU version)"
done

# ── §23 NETHUNTER — USB GADGET ────────────────────────────────────────────────
section "NetHunter USB Gadget"
config_set CONFIG_USB_GADGET && pass "USB gadget subsystem" || fail "CONFIG_USB_GADGET missing"
config_set CONFIG_USB_CONFIGFS && pass "USB ConfigFS" || fail "CONFIG_USB_CONFIGFS missing"
for opt in CONFIG_USB_CONFIGFS_SERIAL CONFIG_USB_CONFIGFS_ACM \
           CONFIG_USB_CONFIGFS_NCM CONFIG_USB_CONFIGFS_ECM \
           CONFIG_USB_CONFIGFS_RNDIS CONFIG_USB_CONFIGFS_F_HID; do
    config_set "${opt}" && pass "${opt}" || fail "${opt} missing — NetHunter USB attack surface incomplete"
done
config_set CONFIG_USB_CONFIGFS_MASS_STORAGE && pass "CONFIG_USB_CONFIGFS_MASS_STORAGE" || \
    warn "CONFIG_USB_CONFIGFS_MASS_STORAGE not set (optional)"

# ── §23 NETHUNTER — EXTERNAL WIFI ────────────────────────────────────────────
section "NetHunter External Wi-Fi"
config_set CONFIG_MAC80211 && pass "CONFIG_MAC80211" || fail "MAC80211 missing — USB Wi-Fi drivers need this"
for opt in CONFIG_ATH9K_HTC CONFIG_RT2800USB CONFIG_MT7601U \
           CONFIG_WLAN_VENDOR_REALTEK CONFIG_RTL8187 CONFIG_RTL8XXXU; do
    config_set "${opt}" && pass "${opt}" || warn "${opt} not set"
done

# ── §23 NETHUNTER — BLUETOOTH ─────────────────────────────────────────────────
section "NetHunter Bluetooth"
for opt in CONFIG_BT_HCIBTUSB CONFIG_BT_HCIBTUSB_BCM CONFIG_BT_HCIBTUSB_RTL \
           CONFIG_BT_HCIUART CONFIG_BT_HCIVHCI; do
    config_set "${opt}" && pass "${opt}" || warn "${opt} not set"
done

# ── §23 NETHUNTER — NETWORK ───────────────────────────────────────────────────
section "NetHunter Network"
config_set CONFIG_TUN && pass "CONFIG_TUN (VPN/OpenVPN)" || fail "CONFIG_TUN missing"
config_set CONFIG_NET_NS && pass "CONFIG_NET_NS" || fail "Network namespaces missing — chroot broken"
config_set CONFIG_PID_NS && pass "CONFIG_PID_NS" || warn "PID namespaces not set"
config_set CONFIG_USB_RTL8152 && pass "CONFIG_USB_RTL8152 (USB Ethernet)" || warn "RTL8152 USB Ethernet not set"

# ── §23 PERFORMANCE (from GKID base) ─────────────────────────────────────────
section "Performance (GKID base preserved)"
config_set CONFIG_LRU_GEN && pass "MGLRU (CONFIG_LRU_GEN)" || warn "MGLRU not set — expected from GKID base"
config_set CONFIG_ZRAM && pass "ZRAM" || warn "ZRAM not set"
config_set CONFIG_CRYPTO_LZ4 && pass "LZ4 compression" || warn "LZ4 not set"
config_set CONFIG_CRYPTO_ZSTD && pass "ZSTD compression" || warn "ZSTD not set (optional)"
config_set CONFIG_TCP_CONG_BBR && pass "BBR congestion control" || warn "BBR not set"
config_set CONFIG_TCP_CONG_WESTWOOD && pass "Westwood+ congestion" || warn "Westwood not set"
config_set CONFIG_NET_SCH_FQ && pass "FQ packet scheduler" || warn "FQ not set"
config_set CONFIG_NET_SCH_FQ_CODEL && pass "FQ-CoDel" || warn "FQ-CoDel not set"

# ── §23 VENDOR COMPATIBILITY ─────────────────────────────────────────────────
section "Vendor Compatibility"
config_set CONFIG_MODVERSIONS && pass "MODVERSIONS present" || fail "MODVERSIONS missing — vendor ABi broken"
# Confirm no changes to Qualcomm WLAN (should still be module)
qca_val=$(config_val CONFIG_QCA_CLD_WLAN 2>/dev/null || echo "NOT_SET")
[[ "${qca_val}" != "NOT_SET" ]] && \
    pass "Qualcomm WLAN driver present (${qca_val})" || \
    warn "CONFIG_QCA_CLD_WLAN not found in config (may be in vendor makefile)"

# ── SAFETY CHECKS ─────────────────────────────────────────────────────────────
section "Safety Checks"
config_not_set CONFIG_KSM && pass "KSM disabled (security)" || fail "KSM enabled — disable for security"
config_not_set CONFIG_ZRAM_WRITEBACK && pass "ZRAM writeback disabled" || \
    warn "ZRAM writeback enabled — ensure partition support exists"

# ── SUMMARY ────────────────────────────────────────────────────────────────────
echo ""
echo "======================================================================"
echo "  Validation Summary"
echo "  PASS: ${PASS}  FAIL: ${FAIL}  WARN: ${WARN}"
echo "======================================================================"

# Write GitHub step summary
{
    echo "## NetHunter Config Validation"
    echo ""
    echo "| Result | Count |"
    echo "|--------|-------|"
    echo "| ✅ PASS | ${PASS} |"
    echo "| ❌ FAIL | ${FAIL} |"
    echo "| ⚠️ WARN | ${WARN} |"
    echo ""
    if [[ ${FAIL} -gt 0 ]]; then
        echo "> ❌ **Validation FAILED** — ${FAIL} mandatory checks did not pass."
    else
        echo "> ✅ **Validation PASSED** — all mandatory checks passed (${WARN} warnings)."
    fi
} >> "${STEP_SUMMARY}" || true

if [[ ${FAIL} -gt 0 ]]; then
    echo "::error::NetHunter config validation FAILED with ${FAIL} failures"
    exit 1
fi

echo "Validation complete: PASS=${PASS} WARN=${WARN}"
exit 0
