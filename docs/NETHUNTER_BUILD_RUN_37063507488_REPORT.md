# 📋 NetHunter Daily Kernel Build Report — Run #37063507488

**Date**: 2026-10-03 02:56 IST (21:26 UTC)  
**Workflow**: [Build Evolution X NetHunter Daily-Driver Kernel](https://github.com/Anurag12shukla/marble-kernel-builder/actions/workflows/build-evolutionx-nethunter.yml)  
**Run ID**: [`37063507488`](https://github.com/Anurag12shukla/marble-kernel-builder/actions/runs/37063507488)  
**Branch**: `feature/marble-evox-nethunter-daily`  
**Commit**: [`e5bf2b2`](https://github.com/Anurag12shukla/marble-kernel-builder/commit/e5bf2b2)  
**Target Device**: POCO F5 / Redmi Note 12 Turbo (`marble` / `marblein`)  

---

## 1. Executive Summary

The repaired GitHub Actions CI build succeeded completely and deterministically. All failures from the previous run (#37043584065) were diagnosed, resolved, and verified.

| Component | Status | Details |
|:---|:---|:---|
| **Build Pipeline** | ✅ **SUCCESS** | Exited `0`, elapsed time **32m 03s** |
| **Kernel Source** | ✅ **VERIFIED** | `Evolution-X-Devices/kernel_xiaomi_sm8450 @ cnb` (`4a234e4dff2373f31709a1d5acfc8eb3d636d571`) |
| **Toolchain** | ✅ **VERIFIED** | LLVM/Clang `22.1.8`, LLD `22.1.8`, ThinLTO (`lto=thin`) |
| **Root Manager** | ✅ **CONFIRMED** | ReSukiSU v4.2.0-rc3-34210a4d (version code `35195`) |
| **Root Hiding** | ✅ **CONFIRMED** | SUSFS v2.3.0 (commit `9892175`) patched & enabled (`CONFIG_KSU_SUSFS=y`) |
| **NetHunter Fragments** | ✅ **APPLIED & VALIDATED** | All 26 mandatory NetHunter configuration symbols verified `=y` |
| **Config Artifact** | ✅ **UPLOADED** | `final-kernel.config` uploaded to dedicated artifact & flash ZIP |
| **Post-Build Validation** | ✅ **PASSED** | 51 PASS, 0 FAIL, 3 WARN (all critical requirements enforced) |
| **Flashable Package** | ✅ **GENERATED** | `AK3_marble_LOS_evolution-x_resukisu-v4.2.0-rc3-34210a4d-code35195_susfs-v2.3.0_r6.zip` (21.5 MB) |
| **Package SHA-256** | 🔒 **VERIFIED** | `cccb7891dbf80a113df86d6e822ad2f6089bbad2db12d5d9bd8276344ffde822` |

---

## 2. Hard Failure Symbols Verification

Verified directly on the generated `final-kernel.config` artifact:

### NetHunter USB Gadget (BadUSB / DuckHunter / CDC Arsenal)
- `CONFIG_USB_GADGET=y`
- `CONFIG_USB_CONFIGFS=y`
- `CONFIG_USB_CONFIGFS_SERIAL=y`
- `CONFIG_USB_CONFIGFS_ACM=y`
- `CONFIG_USB_CONFIGFS_NCM=y`
- `CONFIG_USB_CONFIGFS_ECM=y`
- `CONFIG_USB_CONFIGFS_RNDIS=y`
- `CONFIG_USB_CONFIGFS_F_HID=y`
- `CONFIG_USB_CONFIGFS_MASS_STORAGE=y`

### External Wi-Fi Stack & Drivers (Monitor & Injection Support)
- `CONFIG_CFG80211=y`
- `CONFIG_MAC80211=y`
- `CONFIG_ATH9K_HTC=y`
- `CONFIG_RT2800USB=y`
- `CONFIG_RTL8187=y`
- `CONFIG_MT7601U=y`

### Bluetooth (External USB HCI & Virtual HCI)
- `CONFIG_BT_HCIBTUSB=y`
- `CONFIG_BT_HCIBTUSB_BCM=y`
- `CONFIG_BT_HCIBTUSB_RTL=y`
- `CONFIG_BT_HCIVHCI=y`

### Network & Namespaces (Kali Chroot & USB Networking)
- `CONFIG_NAMESPACES=y`
- `CONFIG_USER_NS=y`
- `CONFIG_PID_NS=y`
- `CONFIG_NET_NS=y`
- `CONFIG_TUN=y`
- `CONFIG_USB_RTL8152=y`
- `CONFIG_USB_NET_RNDIS_HOST=y`

### Root & Root-Hiding (ReSukiSU + SUSFS v2.3.0)
- `CONFIG_KSU=y`
- `CONFIG_KSU_SUSFS=y`

---

## 3. Flash Safety Warning

> [!WARNING]
> This workflow does NOT flash or reboot any device automatically.
> Manual installation requires:
> 1. Verifying the SHA256 checksum against `AK3_marble_LOS_evolution-x_resukisu-v4.2.0-rc3-34210a4d-code35195_susfs-v2.3.0_r6.zip.sha256`.
> 2. Ensuring the current ROM is Evolution X 17.0 (Android 17) for `marble`/`marblein`.
> 3. Flashing via KernelFlasher or custom recovery with a known working boot backup.
