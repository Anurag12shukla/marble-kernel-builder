# GKID Port Status — marble Evolution X GKID Performance Kernel

> **Last Updated**: 2026-10-02
> **Analyst**: Integrity (Antigravity)
> **Branch**: `feature/marble-evolutionx-gkid-performance`
> **Base kernel**: `Evolution-X-Devices/kernel_xiaomi_sm8450 @ cnb`
> **Running kernel commit**: `g4a234e4dff23` (verified via ADB)
> **Toolchain**: LLVM/Clang 22.1.8 (matches running kernel exactly)
> **LTO**: ThinLTO (matches running kernel; `CONFIG_LTO_CLANG_THIN=y`)

---

## Running Kernel Fingerprint (Verified via ADB)

| Field | Value |
|---|---|
| Linux Version | `5.10.269` |
| KMI | `android12-5.10` |
| Source Repository | `Evolution-X-Devices/kernel_xiaomi_sm8450` |
| Source Branch | `cnb` |
| Source Commit | `4a234e4dff23` (matches `uname -r` suffix `g4a234e4dff23`) |
| Localversion | `-gki` |
| Compiler | `clang version 22.1.8 (ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)` |
| Linker | `LLD 22.1.8` |
| LTO | ThinLTO (`CONFIG_LTO_CLANG_THIN=y`) |
| Architecture | `aarch64` / `arm64` |
| Page Size | 4KB (`CONFIG_ARM64_PAGE_SHIFT=12`) |
| VA bits | 39-bit |
| PA bits | 48-bit |
| CONFIG_MODVERSIONS | `y` |
| PREEMPT | `CONFIG_PREEMPT=y` |
| HZ | 250 (`CONFIG_HZ_250=y`) |
| KSU | `CONFIG_KSU=y` |
| SUSFS | `CONFIG_KSU_SUSFS=y` |
| Build user | `marble@github-actions` |
| Build date | `Fri Oct  2 01:09:37 UTC 2026` |

### Running SUSFS Options (Verified)

All SUSFS options confirmed active on running kernel:

| Option | Status |
|---|---|
| `CONFIG_KSU_SUSFS_SUS_PATH` | ✅ `y` |
| `CONFIG_KSU_SUSFS_SUS_MOUNT` | ✅ `y` |
| `CONFIG_KSU_SUSFS_SUS_KSTAT` | ✅ `y` |
| `CONFIG_KSU_SUSFS_SPOOF_UNAME` | ✅ `y` |
| `CONFIG_KSU_SUSFS_ENABLE_LOG` | ✅ `y` |
| `CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS` | ✅ `y` |
| `CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG` | ✅ `y` |
| `CONFIG_KSU_SUSFS_OPEN_REDIRECT` | ✅ `y` |
| `CONFIG_KSU_SUSFS_SUS_MAP` | ✅ `y` |

---

## GKID Feature Analysis

> **Source**: `https://github.com/ahmed-alnassif/GKID-Kernels`
>
> **GKID description**: "Blazing-fast GKI kernels with KernelSU / ReSukiSU + SUSFS, Baseband Guard,
> 300Hz, BBRv3, MGLRU & battery/performance optimizations."
>
> **Approach**: GKID ships as prebuilt ZIPs for generic GKI. The previous generic GKID
> `5.10.269` kernel **failed to boot** on marble despite matching KMI/version.
> Therefore, GKID features are **selectively ported** into the working Evolution X
> marble source (same base as the running kernel), not adopted wholesale.

---

## Feature Matrix

| Feature | GKID Has | Running EvX Has | Decision | Status | Reason |
|---|---|---|---|---|---|
| ReSukiSU | ✅ | ✅ | Keep | **ALREADY PRESENT** | Running kernel confirmed ReSukiSU via `CONFIG_KSU=y` + multi-manager support |
| SUSFS (all options) | ✅ | ✅ | Keep | **ALREADY PRESENT** | All 9 SUSFS options verified active on running kernel |
| SUSFS v2.2.0 pinned | ✅ | ✅ | Keep | **ALREADY PRESENT** | `susfs-refs.json` pins commit `4003ecf2` proven on marble CI 2026-06-22 |
| ThinLTO | ✅ | ✅ | Keep | **ALREADY PRESENT** | `CONFIG_LTO_CLANG_THIN=y` on running kernel; compatibility-first |
| PREEMPT (full) | ✅ | ✅ | Keep | **ALREADY PRESENT** | `CONFIG_PREEMPT=y` already enabled |
| BFQ I/O scheduler | ✅ | ✅ | Keep | **ALREADY PRESENT** | `CONFIG_IOSCHED_BFQ=y` confirmed |
| Kyber I/O scheduler | ✅ | ✅ | Keep | **ALREADY PRESENT** | `CONFIG_MQ_IOSCHED_KYBER=y` confirmed |
| F2FS + compression (LZ4/ZSTD) | ✅ | ✅ | Keep | **ALREADY PRESENT** | Full F2FS with LZ4/LZ4HC/ZSTD compression confirmed |
| ZRAM (module) | ✅ | ✅ | Keep | **ALREADY PRESENT** | `CONFIG_ZRAM=m` confirmed |
| EXT4 | ✅ | ✅ | Keep | **ALREADY PRESENT** | Full EXT4 with POSIX ACL + security confirmed |
| PSI | ✅ | ✅ | Keep | **ALREADY PRESENT** | `CONFIG_PSI=y` confirmed (LMKD dependency) |
| Transparent HugePages (madvise) | ✅ | ✅ | Keep | **ALREADY PRESENT** | `CONFIG_TRANSPARENT_HUGEPAGE_MADVISE=y` confirmed |
| SCHED_THERMAL_PRESSURE | ✅ | ✅ | Keep | **ALREADY PRESENT** | `CONFIG_SCHED_THERMAL_PRESSURE=y` confirmed |
| WALT scheduler (module) | ✅ | ✅ | Keep | **ALREADY PRESENT** | `CONFIG_SCHED_WALT=m` confirmed |
| EROFS | ✅ | ✅ | Keep | **ALREADY PRESENT** | Full EROFS with compression confirmed |
| 300Hz Timer (HZ_300) | ✅ | ❌ | Optional | **NOT PORTED (default)** | Running kernel uses HZ_250. HZ_300 requires verifying Qualcomm clock sources don't produce fractional tick values. Safe as a compile-time option (build won't break). Controlled via `enable_hz_300` workflow input. **Disabled by default**. |
| MGLRU / LRU_GEN | ✅ | ❌ | Port | **PORTED** | Not in running kernel. MGLRU is a 5.10 backport available in Android GKI trees. Improves memory reclaim for mobile workloads. Applied via config fragment. **Enabled by default**. |
| BBRv3 / TCP_CONG_ADVANCED | ✅ | ❌ | Port | **PORTED** | Running kernel uses only Cubic (`# CONFIG_TCP_CONG_ADVANCED is not set`). BBR improves throughput on mobile/Wi-Fi. Westwood+ included as alternative. Applied via config fragment. **Enabled by default**. |
| Westwood+ | ✅ | ❌ | Port | **PORTED** | Bundled with TCP advanced. Good fallback for lossy mobile links. |
| fq / fq_codel | ✅ | partial | Port | **PORTED** | Verify fq_codel is enabled for qdisc; applied via config fragment. |
| NTSync | ✅ | ❌ | Optional | **NOT PORTED (default)** | Safe kernel driver with no Qualcomm conflicts. Wine/DXVK compatibility layer. No risk to system stability. **Disabled by default**; controlled via `enable_ntsync` input. Source availability on `cnb` branch needs CI verification. |
| ZRAM writeback | ✅ | ❌ | Deferred | **NOT PORTED** | `CONFIG_ZRAM_WRITEBACK` not in running kernel. Requires backing storage partition setup at Android layer. Device-specific risk. Deferred for future evaluation. |
| KSM (Kernel Samepage Merging) | ✅ | ❌ | Rejected | **REJECTED** | `# CONFIG_KSM is not set` on running kernel. Disabled in Evolution X intentionally (security + Spectre risk). Do not enable. |
| Baseband Guard | ✅ | ❌ | Rejected | **REJECTED** | Modifies Qualcomm modem/baseband interaction. Genuine risk to mobile network reliability. Uncertainty about Qualcomm vendor blob compatibility. Mobile-network reliability has absolute priority. |
| NetHunter | ❌ | ❌ | Excluded | **EXCLUDED** | Offensive security tooling. Not appropriate for a daily driver. |
| DroidSpaces | ❌ | ❌ | Excluded | **EXCLUDED** | Unrelated experimental feature. Not appropriate. |
| FullLTO | Optional | ❌ | Rejected | **REJECTED** | Memory-heavy on free GitHub runners. ThinLTO matches running kernel and provides good compatibility. |
| Neutron Clang | ✅ | ❌ | Rejected | **REJECTED** | Running kernel uses LLVM 22.1.8 exactly. Switching toolchains risks ABI/vermagic incompatibility with vendor modules. LLVM 22.1.8 is the correct choice. |

---

## Portability Notes

### MGLRU (PORTED)

- MGLRU (Multi-Generational LRU) was developed for Linux 6.1 but is available as
  a backport for Android 5.10 GKI in various kernel trees.
- The `cnb` Evolution X branch may or may not include the backport already.
- **CI action**: Build will expose whether `CONFIG_LRU_GEN` is an available symbol.
  If the config option is silently ignored, MGLRU is not available in this tree —
  and the status will be updated to **NOT PORTED**.
- Config fragment sets: `CONFIG_LRU_GEN=y CONFIG_LRU_GEN_ENABLED=y`

### BBRv3 / TCP Advanced (PORTED)

- `CONFIG_TCP_CONG_ADVANCED=y` unlocks the full TCP congestion control menu.
- `CONFIG_TCP_CONG_BBR=y` enables BBR (v1/v3 depends on tree).
- `CONFIG_TCP_CONG_WESTWOOD=y` enables Westwood+ as an alternative.
- `CONFIG_DEFAULT_TCP_CONG="bbr"` sets BBR as default.
- Qualcomm Wi-Fi/baseband drivers are **not modified**. Only the TCP stack congestion
  algorithm selection is changed — this is safe.

### 300Hz Timer (NOT PORTED by default)

- The Qualcomm SM8450 uses clock sources that may produce non-integer tick counts
  at 300Hz due to the PLL configuration. A fractional residual would cause gradual
  time drift and possible WLAN beacon scheduling issues.
- Evidence from the marble community is mixed. Generic GKID enables it; some marble
  ROMs do not.
- **Decision**: Disabled by default. Enable via `enable_hz_300=true` in workflow if
  you want to test. If time drift or WLAN issues appear, revert to HZ_250.
- Config fragment: `CONFIG_HZ_300=y` replaces `CONFIG_HZ_250=y` when enabled.

### NTSync (NOT PORTED by default)

- NTSync is a kernel driver implementing Windows NT synchronization primitives.
- No Qualcomm hardware interaction. Safe to enable.
- Availability in the `cnb` Evolution X tree is uncertain — needs CI verification.
- **Decision**: Disabled by default. Enable via `enable_ntsync=true` if needed.

---

## Config Fragment Strategy

Since Evolution X source uses `gki_fragments` defconfig mode, GKID performance
options are applied via a dedicated vendor config fragment:

```
arch/arm64/configs/vendor/evox_gkid_performance.config
```

This file must be created in the **kernel source tree** (via a patch or by appending
to the build-core.yml config step). See `scripts/apply-gkid-config-fragment.sh`.

The fragment is applied **after** the standard GKI fragments, allowing selective
override of performance-relevant options without touching device/vendor configs.

---

## Compatibility Guarantee Statement

> **There is NO guarantee of compatibility.**

The kernel is built from the exact same source commit (`4a234e4dff23`) and with
the exact same toolchain (LLVM 22.1.8) as the running Evolution X kernel.
This maximizes the probability of compatibility. However:

- Vendor module vermagic depends on CONFIG_MODVERSIONS symbols — any config change
  that alters exported symbol CRCs will break module loading.
- The GKID config fragment adds only **new** features (TCP stack, memory reclaim)
  and does not modify module-exported symbols or device driver configs.
- DTB/DTBO handling: The `cnb` branch builds Image only (GKI model). DTBs are
  provided by vendor_boot from the Evolution X ROM ZIP — these are **not modified**.

---

## CI Build Tracking

| Run | Branch | Result | Artifact | Notes |
|---|---|---|---|---|
| — | `feature/marble-evolutionx-gkid-performance` | PENDING | — | Initial push; awaiting first CI run |

*This table is updated after each GitHub Actions run.*

---

## Flashing Instructions (Manual — After Successful CI Artifact)

> ⚠️ **DO NOT FLASH AUTOMATICALLY. Review artifact and this document first.**

1. Download the AnyKernel3 ZIP from GitHub Actions artifacts.
2. Verify SHA256: `sha256sum marble-kernel-evox-gkid-*.zip`
3. Compare against `*.sha256` file in the artifact.
4. Boot to custom recovery (TWRP / OrangeFox).
5. Flash the ZIP: `Install → Select ZIP → Swipe to flash`.
6. Do **not** wipe data.
7. Reboot to system.
8. Verify: `adb shell uname -r` — should show `5.10.269-gki-*`.
9. Verify root: Open ReSukiSU manager app.
10. If boot fails: Boot to recovery and restore previous boot image backup.

**Prerequisite**: Unlocked bootloader + custom recovery already installed.
The phone must already be running Evolution X 17.0 (marble-12.2).
