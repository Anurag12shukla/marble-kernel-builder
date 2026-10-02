# 📋 NetHunter Daily Kernel Build Report — Run #37043584065

**Date**: 2026-10-02 23:46 IST (18:16 UTC)  
**Workflow**: [Build Evolution X NetHunter Daily-Driver Kernel](https://github.com/Anurag12shukla/marble-kernel-builder/actions/workflows/build-evolutionx-nethunter.yml)  
**Run ID**: [`37043584065`](https://github.com/Anurag12shukla/marble-kernel-builder/actions/runs/37043584065)  
**Branch**: `feature/marble-evox-nethunter-daily`  
**Target Device**: POCO F5 / Redmi Note 12 Turbo (`marble` / `marblein`)  

---

## 1. Executive Summary

A full end-to-end build was executed on GitHub Actions for the POCO F5 NetHunter Daily-Driver Kernel.

| Component | Status | Details |
|:---|:---|:---|
| **Build Pipeline** | ✅ **SUCCESS** | Exited `0`, elapsed time **20m 26s** |
| **Flashable ZIP** | ✅ **GENERATED** | `AK3_marble_LOS_lineageos_resukisu-v4.2.0-rc3-34210a4d-code35195_susfs-v2.3.0_r4.zip` (19.8 MB) |
| **Kernel Image** | ✅ **VALID** | Linux ARM64 boot executable Image (38.4 MB uncompressed, 4K pages) |
| **Root Manager** | ✅ **CONFIRMED** | ReSukiSU v4.2.0-rc3 (code 35195) |
| **Root Hiding** | ✅ **CONFIRMED** | SUSFS v2.3.0 (commit `9892175`) patched across 21 core kernel files |
| **Artifact SHA-256** | 🔒 **VERIFIED** | `e3d212917c4ff640490b822df572276f4f5132bd25222d17785ec93f0b9b7d2b` |
| **NetHunter Fragments** | ⚠️ **ATTENTION** | **Skipped in this compile run** due to an environment variable isolation bug in `build-core.yml` |
| **Kernel Source Branch**| ⚠️ **ATTENTION** | Built with `LineageOS/android_kernel_xiaomi_sm8450@lineage-23.2` instead of `Evolution-X-Devices` due to `$GITHUB_ENV` test pollution |

---

## 2. Everything That Was Added & Implemented

All changes were implemented on the new dedicated branch [`feature/marble-evox-nethunter-daily`](https://github.com/Anurag12shukla/marble-kernel-builder/tree/feature/marble-evox-nethunter-daily) without modifying or breaking `feature/marble-evolutionx-gkid-performance`:

### 2.1 NetHunter Kernel Configuration Fragments
1. **USB Gadget Stack** (`config/fragments/evox-nethunter-usb.config`):
   - `CONFIG_USB_CONFIGFS_F_HID=y` (BadUSB, DuckHunter keystroke injection)
   - `CONFIG_USB_CONFIGFS_ACM=y`, `CONFIG_USB_CONFIGFS_SERIAL=y` (USB Serial, modem emulation)
   - `CONFIG_USB_CONFIGFS_NCM=y`, `CONFIG_USB_CONFIGFS_ECM=y`, `CONFIG_USB_CONFIGFS_RNDIS=y` (USB Ethernet / NetHunter Arsenal)
   - `CONFIG_USB_CONFIGFS_MASS_STORAGE=y` (DriveDroid / ISO emulation)
2. **External Wi-Fi Adapter Support** (`config/fragments/evox-nethunter-wifi.config`):
   - `CONFIG_ATH9K_HTC=y` (Atheros AR9271 / TP-Link TL-WN722N v1)
   - `CONFIG_RT2800USB=y` (Ralink RT3070 / RT5370 / Alfa AWUS036NEH)
   - `CONFIG_RTL8187=y` (Realtek RTL8187L / Alfa AWUS036H)
   - `CONFIG_MT7601U=y` (MediaTek MT7601U cheap dongles)
   - `CONFIG_CFG80211=y`, `CONFIG_MAC80211=y` (injection/monitor framework)
3. **Bluetooth Hacking & HCI** (`config/fragments/evox-nethunter-bt.config`):
   - `CONFIG_BT_HCIBTUSB=y`, `CONFIG_BT_HCIBTUSB_BCM=y`, `CONFIG_BT_HCIBTUSB_RTL=y` (USB Bluetooth dongles)
   - `CONFIG_BT_HCIVHCI=y` (Virtual Bluetooth HCI for spoofing)
4. **Networking & Container Isolation** (`config/fragments/evox-nethunter-network.config`):
   - `CONFIG_NAMESPACES=y`, `CONFIG_USER_NS=y`, `CONFIG_PID_NS=y`, `CONFIG_NET_NS=y` (Kali Linux chroot / rootfs container)
   - `CONFIG_TUN=y` (OpenVPN, WireGuard, NetHunter VPN tools)
   - `CONFIG_USB_RTL8152=y`, `CONFIG_USB_NET_RNDIS_HOST=y` (USB Ethernet adapters)
5. **Battery & Efficiency Stack** (`config/fragments/evox-battery.config`):
   - `CONFIG_PSI=y` (Pressure Stall Information for low-latency memory management)
   - `CONFIG_CRYPTO_AES_ARM64_CE=y`, `CONFIG_CRYPTO_SHA2_ARM64_CE=y` (Hardware crypto acceleration)
   - `CONFIG_CRYPTO_ZSTD=y` (Fast kernel compression)

### 2.2 Automation & Validation Scripts
- `scripts/apply-nethunter-config-fragments.sh`: Merges the 5 fragment files sequentially after defconfig.
- `scripts/validate-nethunter-config.sh`: Audits `.config` against 35+ mandatory NetHunter symbols with strict compliance checks.
- `.github/workflows/build-evolutionx-nethunter.yml`: Dedicated GitHub Actions workflow with inputs for toolchain, LTO, commit pinning, SUSFS version, and config validation.
- `docs/MARBLE_NETHUNTER_FEATURE_MANIFEST.md`: Complete hardware matrix, status registry, and security guidelines.

---

## 3. What Went Wrong During Build Run #37043584065

While the GitHub Actions runner completed with a green checkmark (`success`), an audit of the downloaded logs and build artifacts revealed three specific issues:

### ⚠️ Issue 1: Environment Variable Pollution Overrode Kernel Source to LineageOS
* **What Happened**:
  In `.github/workflows/build-evolutionx-nethunter.yml`, `run_policy_tests: true` was enabled on the `build-core.yml` call.
  Inside `build-core.yml`, the policy validation step ran `tests/test-toolchain-auto.sh`.
  Line 19 of `tests/test-toolchain-auto.sh` executes:
  ```bash
  out="$(KERNEL_SOURCE=lineageos SOURCE_REF='' TOOLCHAIN=android-r416183b bash scripts/resolve-toolchain.sh)"
  ```
  `scripts/resolve-toolchain.sh` calls `scripts/resolve-kernel-source.sh`, which writes:
  ```python
  with open(gh_env, "a") as fh:
      fh.write("KERNEL_SOURCE=lineageos\n")
      fh.write("TOOLCHAIN=android-r416183b\n")
  ```
  Because `$GITHUB_ENV` was exposed to tests, it **permanently mutated the GitHub runner environment**, overwriting `KERNEL_SOURCE: evolution-x` with `lineageos` and `TOOLCHAIN` with `android-r416183b` for all subsequent steps!
* **Result**:
  The kernel source compiled was `LineageOS/android_kernel_xiaomi_sm8450@lineage-23.2` rather than `Evolution-X-Devices/kernel_xiaomi_sm8450@cnb`.

---

### ⚠️ Issue 2: `ARTIFACT_LABEL` Was Not Passed to `build-kernel.sh`
* **What Happened**:
  `scripts/build-kernel.sh` checks:
  ```bash
  if [[ "${ARTIFACT_LABEL:-}" == *nethunter* ]]; then
    bash "${NH_SCRIPT}"
  fi
  ```
  However, in `.github/workflows/build-core.yml`, `ARTIFACT_LABEL` was never declared under the `env:` block.
* **Result**:
  `${ARTIFACT_LABEL}` evaluated to an empty string inside `build-kernel.sh`. The NetHunter config fragments (`apply-nethunter-config-fragments.sh`) were **silently skipped** during kernel configuration!

---

### ⚠️ Issue 3: Missing `.config` in Artifacts Skipped Downstream Validation
* **What Happened**:
  The compiled `.config` was stored in the runner's build directory but was not packaged as an uploaded artifact by `build-core.yml`.
* **Result**:
  The `NetHunter Config Validation` step reported:
  `! kernel .config not found in artifacts — skipping validation` and gracefully exited without catching Issue #2.

---

## 4. Key Build Log Excerpts

### 4.1 ReSukiSU Application
```text
[+] Setting up KernelSU...
Cloning into 'KernelSU'...
Wild-style manager version: commits=4495 base=30000 code=34495 (git: kernel-source/KernelSU)
Manager version code: 35195
Manager version name: v4.2.0-rc3-34210a4d@ReSukiSU
```

### 4.2 SUSFS Patch Application
```text
Cloning into 'susfs4ksu'...
HEAD is now at 9892175 kernel: SUS_KSTAT: Fix the wrong type of member "is_statically"
patching file drivers/input/input.c
patching file fs/Makefile
patching file fs/exec.c
patching file fs/namei.c
patching file fs/namespace.c
patching file fs/notify/fdinfo.c
patching file fs/open.c
patching file fs/proc/base.c
patching file fs/proc/bootconfig.c
patching file fs/proc/fd.c
patching file fs/proc/task_mmu.c
patching file fs/proc_namespace.c
patching file fs/read_write.c
patching file fs/readdir.c
patching file fs/stat.c
patching file fs/statfs.c
patching file fs/super.c
patching file kernel/kallsyms.c
patching file kernel/reboot.c
patching file kernel/sys.c
patching file mm/memory.c
patching file security/selinux/avc.c
patching file security/selinux/hooks.c
patching file security/selinux/selinuxfs.c
Using manager-side SUSFS support from ReSukiSU/ReSukiSU@main
SUSFS applied from 9892175b4acec7ee844e113b8d02c0f4d12cdfac
```

### 4.3 Compiler & Linker Execution
```text
Compiler: clang-r416183b (Android Clang)
Target: aarch64-linux-gnu
LTO: ThinLTO
Build duration: 20 minutes 26 seconds
Output: kernel-source/out/arch/arm64/boot/Image (38,407,860 bytes)
```

### 4.4 AnyKernel3 Packaging & Audit
```text
zip_path=kernel-source/release/AK3_marble_LOS_lineageos_resukisu-v4.2.0-rc3-34210a4d-code35195_susfs-v2.3.0_r4.zip
zip_size=19794250 bytes
zip_entries=27 files
image_file_type=Linux kernel ARM64 boot executable Image, little-endian, 4K pages
zip_sha256=e3d212917c4ff640490b822df572276f4f5132bd25222d17785ec93f0b9b7d2b
```

### 4.5 Ccache Statistics
```text
Cacheable calls:   2896 / 4459 (64.95%)
  Hits:              99 / 2896 ( 3.42%)
    Direct:          99 /   99 (100.0%)
  Misses:          2797 / 2896 (96.58%)
Uncacheable calls: 1563 / 4459 (35.05%)
Cache size:        0.5 GB / 4.0 GB
```

---

## 5. Immediate Remediation Plan (Run #5)

To guarantee the next build uses the exact Evolution X source with full NetHunter fragments and LLVM 22.1.8, the following three fixes are ready to apply:

1. **In `build-core.yml`**:
   - Add `ARTIFACT_LABEL: ${{ inputs.artifact_label }}` to the job's `env:` block so `build-kernel.sh` detects the NetHunter profile.
   - Also upload `.config` to artifacts so `validate-nethunter-config.sh` can verify every single NetHunter driver option.
2. **In `build-evolutionx-nethunter.yml`**:
   - Change `run_policy_tests: false` (identical to `build-matrix.yml`) to completely prevent test scripts from polluting the runner's `$GITHUB_ENV`.
3. **Trigger Build Run #5**:
   - Compiles Evolution X (`Evolution-X-Devices/kernel_xiaomi_sm8450@cnb`, commit `4a234e4dff23`).
   - Injects USB HID, Wi-Fi drivers, Bluetooth HCI, Network namespaces, and Battery fragments.
   - Enforces post-build verification with `validate-nethunter-config.sh`.
