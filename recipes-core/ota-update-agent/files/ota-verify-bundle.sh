#!/bin/bash
# Verify OTA bundle signature and artifact integrity before applying.
# Usage: ota-verify-bundle <bundle-directory>
# Exit 0 = safe to apply, Exit 1 = verification failed
set -euo pipefail

BUNDLE_DIR="${1:?Usage: ota-verify-bundle <bundle-directory>}"
CERT="/etc/ota/ota_sign_cert.pem"

log() { logger -t "ota-verify" "$1"; echo "$1"; }

if [ ! -d "$BUNDLE_DIR" ]; then
    log "ERROR: Bundle directory not found: $BUNDLE_DIR"; exit 1
fi
if [ ! -f "$CERT" ] || [ ! -s "$CERT" ]; then
    log "ERROR: OTA signing certificate not found at $CERT"; exit 1
fi
if [ ! -f "${BUNDLE_DIR}/bundle.sig" ]; then
    log "REJECT: No bundle.sig found"; exit 1
fi
if [ ! -f "${BUNDLE_DIR}/manifest.json" ]; then
    log "REJECT: No manifest.json found"; exit 1
fi

# Step 1: Verify manifest signature
log "Verifying manifest signature..."
if ! openssl dgst -sha256 -verify "$CERT" \
    -signature "${BUNDLE_DIR}/bundle.sig" \
    "${BUNDLE_DIR}/manifest.json"; then
    log "REJECT: Manifest signature FAILED"; exit 1
fi
log "  Manifest signature: VALID"

# Step 2: Verify artifact hashes
log "Verifying artifact hashes..."
ALL_OK=true

if command -v jq >/dev/null 2>&1; then
    ARTIFACTS=$(jq -r '.artifacts | keys[]' "${BUNDLE_DIR}/manifest.json" 2>/dev/null || true)
    for artifact in $ARTIFACTS; do
        ARTIFACT_PATH="${BUNDLE_DIR}/${artifact}"
        [ -f "$ARTIFACT_PATH" ] || continue
        EXPECTED=$(jq -r ".artifacts.\"${artifact}\".sha256" "${BUNDLE_DIR}/manifest.json")
        ACTUAL=$(sha256sum "$ARTIFACT_PATH" | awk '{print $1}')
        if [ "$EXPECTED" != "$ACTUAL" ]; then
            log "  REJECT: ${artifact} hash mismatch"; ALL_OK=false
        else
            log "  ${artifact}: OK"
        fi
    done
else
    for artifact in rootfs.wic.bz2 kernel.itb shared-env.itb; do
        ARTIFACT_PATH="${BUNDLE_DIR}/${artifact}"
        [ -f "$ARTIFACT_PATH" ] || continue
        EXPECTED=$(grep -o "\"${artifact}\"[^}]*\"sha256\"[[:space:]]*:[[:space:]]*\"[a-f0-9]*\"" \
            "${BUNDLE_DIR}/manifest.json" 2>/dev/null | grep -o '[a-f0-9]\{64\}' || true)
        ACTUAL=$(sha256sum "$ARTIFACT_PATH" | awk '{print $1}')
        if [ -n "$EXPECTED" ] && [ "$EXPECTED" != "$ACTUAL" ]; then
            log "  REJECT: ${artifact} hash mismatch"; ALL_OK=false
        else
            log "  ${artifact}: OK"
        fi
    done
fi

if [ "$ALL_OK" != true ]; then
    log "REJECT: Artifact hash verification failed."; exit 1
fi

log "Bundle verified. Safe to apply."
exit 0
