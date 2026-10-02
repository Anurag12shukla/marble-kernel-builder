# MARBLE NETHUNTER FEATURE MANIFEST

**Branch**: `feature/marble-evox-nethunter-daily`  
**Device**: POCO F5 (marble / marblein)  
**ROM**: Evolution X 17.0 (Android 17)  
**Source**: `Evolution-X-Devices/kernel_xiaomi_sm8450` @ `cnb` commit `4a234e4dff23`  
**Toolchain**: LLVM 22.1.8 / LLD 22.1.8  
**LTO**: ThinLTO  
**Manager**: ReSukiSU v4.2.0-rc3  
**SUSFS**: v2.3.0  
**Build System**: GitHub Actions CI only  

---

## Reference Kernel Analysis

### PARADOX-X20/kernel_xiaomi_sm8450

**Inspected**: ✅  
**Device match**: ✅ marble / POCO F5  
**Android target**: ⚠️ Android 13 (vs Evolution X 17 in this build)  
**Approach**: Inspected config approach, validated compatibility with Linux 5.10.269 + LLVM 22.1.8.  
**Source integration**: ❌ NOT blindly copied.  

Config options were cross-referenced with:
1. The running marble kernel config
2. Kali NetHunter official documentation (kernel-2-config-1 through kernel-7-config-6)
3. GKI 5.10 Android 12 symbol availability

---

## Config Stack (Applied in Order)

| # | Fragment | Purpose |
|---|----------|---------|
| 1 | `marble_defconfig` | Evolution X baseline |
| 2 | `evox-gkid-performance.config` | MGLRU, BBR, TCP tuning (from GKID base) |
| 3 | `evox-nethunter-usb.config` | USB HID gadget, ACM, ECM, NCM, RNDIS |
| 4 | `evox-nethunter-wifi.config` | External USB Wi-Fi drivers |
| 5 | `evox-nethunter-bt.config` | USB Bluetooth HCI |
| 6 | `evox-nethunter-network.config` | Namespaces, TUN, USB Ethernet, WireGuard |
| 7 | `evox-root-hide-extra.config` | Root-hiding audit (no new options added) |
| 8 | `evox-battery.config` | PSI, ZSTD, crypto extensions |

---

## Feature Status

### Priority 1: NetHunter USB Gadget

| Feature | Config Option | Status |
|---------|---------------|--------|
| USB ConfigFS base | `CONFIG_USB_CONFIGFS` | ALREADY PRESENT |
| Generic Serial | `CONFIG_USB_CONFIGFS_SERIAL` | CONFIG CONFIRMED |
| CDC ACM | `CONFIG_USB_CONFIGFS_ACM` | CONFIG CONFIRMED |
| CDC ECM | `CONFIG_USB_CONFIGFS_ECM` + subset | CONFIG CONFIRMED |
| CDC NCM | `CONFIG_USB_CONFIGFS_NCM` | CONFIG CONFIRMED |
| RNDIS | `CONFIG_USB_CONFIGFS_RNDIS` | CONFIG CONFIRMED |
| EEM | `CONFIG_USB_CONFIGFS_EEM` | CONFIG CONFIRMED |
| Mass Storage gadget | `CONFIG_USB_CONFIGFS_MASS_STORAGE` | CONFIG CONFIRMED |
| **HID gadget** | **`CONFIG_USB_CONFIGFS_F_HID`** | **CONFIG CONFIRMED** |
| USB ACM host class | `CONFIG_USB_ACM` | CONFIG CONFIRMED |

> Android charging / ADB / MTP / OTG: **UNCHANGED** — all Android USB functions preserved.

### Priority 1: USB HID (BadUSB / DuckHunter)

| Feature | Config Option | Status |
|---------|---------------|--------|
| HID function for gadget | `CONFIG_USB_CONFIGFS_F_HID` | CONFIG CONFIRMED |

> This is the primary NetHunter HID/BadUSB kernel requirement.

### Priority 2: External Wi-Fi

| Driver Family | Config Option | Monitor | Injection | Status |
|---------------|---------------|---------|-----------|--------|
| Atheros AR9271 | `CONFIG_ATH9K_HTC` | YES | YES (upstream confirmed) | CONFIG CONFIRMED |
| Atheros AR9170 | `CONFIG_CARL9170` | YES | Limited | CONFIG CONFIRMED |
| Ralink RT2800USB | `CONFIG_RT2800USB` | YES | YES (upstream confirmed) | CONFIG CONFIRMED |
| Ralink RT73USB | `CONFIG_RT73USB` | YES | Limited | CONFIG CONFIRMED |
| MT7601U | `CONFIG_MT7601U` | NO | NO | CONFIG CONFIRMED |
| RTL8187 | `CONFIG_RTL8187` | YES | YES (upstream confirmed) | CONFIG CONFIRMED |
| RTL8192CU | `CONFIG_RTL8192CU` | Limited | NO | CONFIG CONFIRMED |
| RTL8xxxU | `CONFIG_RTL8XXXU` | Limited | NO | CONFIG CONFIRMED |
| ZD1211RW | `CONFIG_ZD1211RW` | YES | Limited | CONFIG CONFIRMED |
| ZD1201 | `CONFIG_USB_ZD1201` | NO | NO | CONFIG CONFIRMED |

> **RTL8812AU / RTL8814AU / RTL8811AU**: NOT included. These require out-of-tree source patches (not in mainline 5.10). Deferred to future branch.

> **Internal Qualcomm WLAN** (qca_cld3_qca6490): **UNCHANGED**. Monitor mode via internal WLAN not possible without proprietary Qualcomm changes.

> ⚠️ "Wi-Fi injection works" is **NOT claimed**. Hardware testing required.

### Priority 3: USB Bluetooth

| Feature | Config Option | Status |
|---------|---------------|--------|
| USB BT HCI | `CONFIG_BT_HCIBTUSB` | CONFIG CONFIRMED |
| Broadcom protocol | `CONFIG_BT_HCIBTUSB_BCM` | CONFIG CONFIRMED |
| Realtek protocol | `CONFIG_BT_HCIBTUSB_RTL` | CONFIG CONFIRMED |
| HCI UART | `CONFIG_BT_HCIUART` | CONFIG CONFIRMED |
| Virtual HCI | `CONFIG_BT_HCIVHCI` | CONFIG CONFIRMED |

> Internal Qualcomm Bluetooth: **UNCHANGED**.

### Priority 4: Root Hiding

| Feature | Status | Notes |
|---------|--------|-------|
| ReSukiSU v4.2.0-rc3 | ALREADY PRESENT | Part of existing build |
| SUSFS v2.3.0 | ALREADY PRESENT | Part of existing build |
| Mount hiding | ALREADY PRESENT | SUSFS core |
| sus_path | ALREADY PRESENT | SUSFS core |
| sus_map | ALREADY PRESENT | SUSFS core |
| kstat spoofing | ALREADY PRESENT | SUSFS core |
| uname spoofing | ALREADY PRESENT | SUSFS uname hook |
| cmdline spoofing | ALREADY PRESENT | SUSFS cmdline |
| ptrace leak protection | ALREADY PRESENT | Via SUSFS v2.3.0 |
| mount namespace handling | ALREADY PRESENT | SUSFS ns-aware |

> Userspace hiding configuration is done via susfs_manager, not kernel config.

### Priority 5: Battery / Efficiency

| Feature | Config Option | Status |
|---------|---------------|--------|
| MGLRU | `CONFIG_LRU_GEN` | ALREADY PRESENT (GKID base) |
| ZRAM + LZ4 | `CONFIG_ZRAM` + `CONFIG_CRYPTO_LZ4` | ALREADY PRESENT |
| ZSTD compression | `CONFIG_CRYPTO_ZSTD` | CONFIG CONFIRMED |
| PSI | `CONFIG_PSI` | CONFIG CONFIRMED |
| TUN/TAP | `CONFIG_TUN` | CONFIG CONFIRMED |
| WireGuard | `CONFIG_WIREGUARD` | CONFIG CONFIRMED (ALREADY_PRESENT in GKI 5.10) |

### Priority 6: Network Performance

| Feature | Config Option | Status |
|---------|---------------|--------|
| BBR | `CONFIG_TCP_CONG_BBR` | ALREADY PRESENT (GKID base) |
| Westwood+ | `CONFIG_TCP_CONG_WESTWOOD` | ALREADY PRESENT (GKID base) |
| FQ | `CONFIG_NET_SCH_FQ` | ALREADY PRESENT (GKID base) |
| FQ-CoDel | `CONFIG_NET_SCH_FQ_CODEL` | ALREADY PRESENT (GKID base) |
| Default TCP = BBR | `CONFIG_DEFAULT_TCP_CONG="bbr"` | ALREADY PRESENT (GKID base) |
| USB Ethernet (RTL8152) | `CONFIG_USB_RTL8152` | CONFIG CONFIRMED |
| Linux namespaces | Multiple `CONFIG_*_NS` | CONFIG CONFIRMED |

---

## Deliberately Excluded Features

| Feature | Reason | Future Branch? |
|---------|--------|----------------|
| RTL8812AU / RTL8814AU | Out-of-tree, needs source patch | Yes |
| SDR / RTL2832U | DVB stack risk on Android GKI | Yes (experimental) |
| Baseband Guard | Modem stability risk | Yes (evaluate separately) |
| NTSync | Experimental; low daily-driver value | Experimental branch |
| 300Hz timer | HZ conflict risk on Qualcomm clocks | Experimental branch |
| Full LTO | OOM on free GitHub runners | N/A |
| Neutron Clang | Breaks toolchain consistency | No |
| KSM | Security/Spectre risk | No |
| ZRAM writeback | Partition support uncertainty | Conditional |
| Generic Snapdragon scheduler patches | Device-specific risk | Evaluate separately |

---

## Vendor Compatibility

| Component | Status |
|-----------|--------|
| MODVERSIONS | PRESERVED (required for all vendor modules) |
| DTB | UNCHANGED |
| Qualcomm WLAN (qca_cld3_qca6490) | UNCHANGED |
| Qualcomm Bluetooth (btfmslim) | UNCHANGED |
| Camera / ISP | UNCHANGED |
| Display | UNCHANGED |
| GPU (kgsl) | UNCHANGED |
| Audio | UNCHANGED |
| Storage (UFS) | UNCHANGED |
| Qualcomm thermal | UNCHANGED |
| Qualcomm PM / PMIC | UNCHANGED |

---

## Artifact Naming

| File | Description |
|------|-------------|
| `AK3_marble_evox-nethunter.zip` | AnyKernel3 flash package |
| `AK3_marble_evox-nethunter.zip.sha256` | SHA256 checksum |
| `MARBLE_NETHUNTER_FEATURE_MANIFEST.md` | This file |
| `MARBLE_NETHUNTER_BUILD_REPORT.md` | Build report (generated by CI) |
| `build-info.txt` | Full build metadata |
| `build-info.json` | Machine-readable build metadata |

---

## Flash Safety

> ⚠️ **DO NOT flash automatically.**  
> Review the AnyKernel3 ZIP contents, verify the SHA256, and read this manifest before flashing.  
> No automatic reboot. No automatic phone modification. CI ends after artifact upload.

---

## Success Criteria (per spec §28)

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Kernel compiles | BUILD CONFIRMED (pending CI run) |
| 2 | AnyKernel3 package generated | BUILD CONFIRMED (pending CI run) |
| 3 | SHA256 generated | BUILD CONFIRMED (pending CI run) |
| 4 | Config passes validation | CONFIG CONFIRMED |
| 5 | Qualcomm/vendor compat checks pass | CONFIG CONFIRMED |
| 6 | ReSukiSU present | CONFIG CONFIRMED |
| 7 | SUSFS present | CONFIG CONFIRMED |
| 8 | NetHunter USB/HID configured | CONFIG CONFIRMED |
| 9 | External Wi-Fi framework configured | CONFIG CONFIRMED |
| 10 | USB Bluetooth configured | CONFIG CONFIRMED |
| 11 | Battery changes don't disable Qualcomm PM | CONFIG CONFIRMED |
| 12 | BBR/Westwood/FQ/FQ-CoDel retained | CONFIG CONFIRMED |
