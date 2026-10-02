#!/usr/bin/env bash
# =============================================================================
# apply-nethunter-config-fragments.sh
# Apply NetHunter config fragments to the Evolution X kernel build
# =============================================================================
# Usage: called from build-core.yml after marble_defconfig is applied
# Fragments applied in order:
#   1. evox-gkid-performance.config  (applied by apply-gkid-config-fragment.sh)
#   2. evox-nethunter-usb.config
#   3. evox-nethunter-wifi.config
#   4. evox-nethunter-bt.config
#   5. evox-nethunter-network.config
#   6. evox-root-hide-extra.config   (audit only — no new options currently)
#   7. evox-battery.config
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FRAGMENT_DIR="${REPO_ROOT}/config/fragments"

# Kernel directory (passed by build-core.yml)
KERNEL_DIR="${KERNEL_DIR:-kernel-source}"
OUT_DIR="${OUT_DIR:-out}"

ARCH="${ARCH:-arm64}"

log() { echo "[nethunter-fragments] $*"; }
warn() { echo "::warning::[nethunter-fragments] $*"; }
error() { echo "::error::[nethunter-fragments] $*"; exit 1; }

# ── Validate environment ──────────────────────────────────────────────────────
[[ -d "${KERNEL_DIR}" ]] || error "KERNEL_DIR not found: ${KERNEL_DIR}"
[[ -f "${KERNEL_DIR}/${OUT_DIR}/.config" ]] || \
    error ".config not found at ${KERNEL_DIR}/${OUT_DIR}/.config — run defconfig first"

pushd "${KERNEL_DIR}" > /dev/null

# ── Helper: apply a single .config fragment using scripts/config ──────────────
apply_fragment() {
    local fragment_path="$1"
    local fragment_name
    fragment_name="$(basename "${fragment_path}")"

    log "Applying fragment: ${fragment_name}"

    # Filter out comment lines and blank lines; apply each CONFIG_ directive
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "${line}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        if [[ "${line}" =~ ^CONFIG_([A-Z0-9_]+)=(.*)$ ]]; then
            local config_name="${BASH_REMATCH[1]}"
            local config_val="${BASH_REMATCH[2]}"
            # Remove inline comments
            config_val="${config_val%%#*}"
            config_val="${config_val%%[[:space:]]}"

            if [[ "${config_val}" == "y" ]]; then
                ./scripts/config --file "${OUT_DIR}/.config" -e "${config_name}"
            elif [[ "${config_val}" == "m" ]]; then
                ./scripts/config --file "${OUT_DIR}/.config" -m "${config_name}"
            elif [[ "${config_val}" == "n" ]]; then
                ./scripts/config --file "${OUT_DIR}/.config" -d "${config_name}"
            elif [[ "${config_val}" =~ ^\"(.*)\"$ ]]; then
                ./scripts/config --file "${OUT_DIR}/.config" \
                    --set-str "${config_name}" "${BASH_REMATCH[1]}"
            else
                ./scripts/config --file "${OUT_DIR}/.config" \
                    --set-val "${config_name}" "${config_val}"
            fi
        elif [[ "${line}" =~ ^#[[:space:]]*CONFIG_([A-Z0-9_]+)[[:space:]]+is[[:space:]]+not[[:space:]]+set ]]; then
            local config_name="${BASH_REMATCH[1]}"
            ./scripts/config --file "${OUT_DIR}/.config" -d "${config_name}"
        fi
    done < "${fragment_path}"

    log "Done: ${fragment_name}"
}

# ── Apply fragments in order ──────────────────────────────────────────────────
NH_FRAGMENTS=(
    "evox-nethunter-usb.config"
    "evox-nethunter-wifi.config"
    "evox-nethunter-bt.config"
    "evox-nethunter-network.config"
    # evox-root-hide-extra.config is documentation-only; no active CONFIG lines
    "evox-battery.config"
)

for frag in "${NH_FRAGMENTS[@]}"; do
    frag_path="${FRAGMENT_DIR}/${frag}"
    if [[ -f "${frag_path}" ]]; then
        apply_fragment "${frag_path}"
    else
        warn "Fragment not found (skipping): ${frag_path}"
    fi
done

# ── Regenerate .config to resolve dependencies ─────────────────────────────────
log "Resolving config dependencies with olddefconfig..."
make O="${OUT_DIR}" ARCH="${ARCH}" LLVM=1 LLVM_IAS=1 olddefconfig 2>&1 | \
    grep -v "^#" || true

log "NetHunter config fragments applied successfully."

popd > /dev/null

# ── Print summary ─────────────────────────────────────────────────────────────
echo "## NetHunter Config Fragment Application" >> "${GITHUB_STEP_SUMMARY:-/dev/null}" || true
echo "" >> "${GITHUB_STEP_SUMMARY:-/dev/null}" || true
echo "| Fragment | Status |" >> "${GITHUB_STEP_SUMMARY:-/dev/null}" || true
echo "|----------|--------|" >> "${GITHUB_STEP_SUMMARY:-/dev/null}" || true
for frag in "${NH_FRAGMENTS[@]}"; do
    if [[ -f "${FRAGMENT_DIR}/${frag}" ]]; then
        echo "| ${frag} | ✅ Applied |" >> "${GITHUB_STEP_SUMMARY:-/dev/null}" || true
    else
        echo "| ${frag} | ⚠️ Missing |" >> "${GITHUB_STEP_SUMMARY:-/dev/null}" || true
    fi
done
