#!/bin/bash
# Verify OTA bundle signature and artifact integrity before applying.
#
# Usage: ota-verify-bundle <bundle-directory>
#
# Expected bundle structure:
#   bundle-dir/
#     manifest.json    ← JSON manifest listing artifacts + SHA-256 hashes
#     bundle.sig       ← RSA signature of manifest.json
#     rootfs.wic.bz2   ← (optional) rootfs image
#     kernel.itb       ← (optional) FIT image
#     shared-env.itb   ← (optional) shared env FIT
#
# Runtime configuration:
#   /etc/vk-secure.conf
#     VK_OTA_BUNDLE_VERIFY_MODE=enforce|warn|off
#
# Modes:
#   enforce (default): any verification failure blocks update (exit 1)
#   warn:              failures are logged but update is allowed (exit 0)
#   off:               skip all verification and allow update (exit 0)
#
# Exit codes:
#   0 — verified OK (or bypass mode allowed it)
#   1 — verification failed in enforce mode
set -euo pipefail

BUNDLE_DIR="${1:-}"
CERT="/etc/ota/ota_sign_cert.pem"

log() { logger -t "ota-verify" "$1"; echo "$1"; }

# -------------------------
# Load runtime verify mode
# -------------------------
MODE="enforce"
if [ -f /etc/vk-secure.conf ]; then
  # shellcheck disable=SC1091
  . /etc/vk-secure.conf
  MODE="${VK_OTA_BUNDLE_VERIFY_MODE:-enforce}"
fi

reject_or_warn() {
  local msg="$1"
  case "$MODE" in
    enforce)
      log "REJECT: $msg"
      exit 1
      ;;
    warn)
      log "WARNING (bypass enabled): $msg"
      exit 0
      ;;
    off)
      log "INFO: Verification disabled (off). Allowing update. Reason: $msg"
      exit 0
      ;;
    *)
      log "ERROR: Invalid VK_OTA_BUNDLE_VERIFY_MODE='$MODE' (expected enforce|warn|off)"
      exit 1
      ;;
  esac
}

if [ "$MODE" = "off" ]; then
  log "INFO: VK_OTA_BUNDLE_VERIFY_MODE=off — skipping OTA bundle verification."
  exit 0
fi

# -------------------------
# Preflight checks
# -------------------------
if [ -z "$BUNDLE_DIR" ]; then
  reject_or_warn "No bundle directory argument provided. Usage: ota-verify-bundle <bundle-directory>"
fi

if [ ! -d "$BUNDLE_DIR" ]; then
  reject_or_warn "Bundle directory not found: $BUNDLE_DIR"
fi

if [ ! -f "$CERT" ] || [ ! -s "$CERT" ]; then
  reject_or_warn "OTA signing certificate not found or empty at $CERT"
fi

if [ ! -f "${BUNDLE_DIR}/bundle.sig" ]; then
  reject_or_warn "No bundle signature (bundle.sig) found in ${BUNDLE_DIR}"
fi

if [ ! -f "${BUNDLE_DIR}/manifest.json" ]; then
  reject_or_warn "No manifest (manifest.json) found in ${BUNDLE_DIR}"
fi

# -------------------------
# Step 1: Verify manifest signature
# -------------------------
log "Step 1: Verifying manifest signature (mode=${MODE})..."
if ! openssl dgst -sha256 -verify "$CERT" \
  -signature "${BUNDLE_DIR}/bundle.sig" \
  "${BUNDLE_DIR}/manifest.json"; then
  reject_or_warn "Manifest signature verification FAILED"
fi
log "  Manifest signature: VALID"

# -------------------------
# Step 2: Verify artifact hashes
# -------------------------
log "Step 2: Verifying artifact hashes..."
ALL_OK=true

if command -v jq >/dev/null 2>&1; then
  ARTIFACTS=$(jq -r '.artifacts | keys[]' "${BUNDLE_DIR}/manifest.json" 2>/dev/null || true)

  if [ -z "$ARTIFACTS" ]; then
    log "WARNING: No artifacts listed in manifest."
  fi

  for artifact in $ARTIFACTS; do
    ARTIFACT_PATH="${BUNDLE_DIR}/${artifact}"

    if [ ! -f "$ARTIFACT_PATH" ]; then
      log "WARNING: ${artifact} listed in manifest but not found in bundle. Skipping."
      continue
    fi

    EXPECTED=$(jq -r ".artifacts.\"${artifact}\".sha256" "${BUNDLE_DIR}/manifest.json")
    ACTUAL=$(sha256sum "$ARTIFACT_PATH" | awk '{print $1}')

    if [ -z "$EXPECTED" ] || [ "$EXPECTED" = "null" ]; then
      log "WARNING: Manifest missing sha256 for ${artifact}. Skipping hash check."
      continue
    fi

    if [ "$EXPECTED" != "$ACTUAL" ]; then
      log "FAIL: ${artifact} hash mismatch"
      log "  expected: ${EXPECTED}"
      log "  actual:   ${ACTUAL}"
      ALL_OK=false
    else
      SIZE=$(stat -c%s "$ARTIFACT_PATH" 2>/dev/null || echo "?")
      log "  ${artifact}: OK (${SIZE} bytes)"
    fi
  done
else
  log "WARNING: jq not available. Using fallback parser for known artifacts."

  for artifact in rootfs.wic.bz2 kernel.itb shared-env.itb; do
    ARTIFACT_PATH="${BUNDLE_DIR}/${artifact}"
    [ -f "$ARTIFACT_PATH" ] || continue

    EXPECTED=$(grep -o "\"${artifact}\"[^}]*\"sha256\"[[:space:]]*:[[:space:]]*\"[a-f0-9]*\"" \
      "${BUNDLE_DIR}/manifest.json" 2>/dev/null | grep -o '[a-f0-9]\{64\}' || true)
    ACTUAL=$(sha256sum "$ARTIFACT_PATH" | awk '{print $1}')

    if [ -z "$EXPECTED" ]; then
      log "WARNING: Cannot extract sha256 for ${artifact} from manifest. Skipping."
      continue
    fi

    if [ "$EXPECTED" != "$ACTUAL" ]; then
      log "FAIL: ${artifact} hash mismatch"
      ALL_OK=false
    else
      log "  ${artifact}: OK"
    fi
  done
fi

if [ "$ALL_OK" != true ]; then
  reject_or_warn "One or more artifact hashes do not match the manifest"
fi

log "==============================="
log "Bundle verified. Safe to apply."
log "==============================="
exit 0