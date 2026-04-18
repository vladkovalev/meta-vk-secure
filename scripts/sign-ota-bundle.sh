#!/bin/bash
# Sign OTA update bundle for LS1046A targets.
# Usage: sign-ota-bundle.sh <bundle-dir> <key-dir>
set -euo pipefail

BUNDLE_DIR="${1:?Usage: sign-ota-bundle.sh <bundle-dir> <key-dir>}"
KEY_DIR="${2:?Usage: sign-ota-bundle.sh <bundle-dir> <key-dir>}"
KEY="${KEY_DIR}/ota_sign_key.pem"
CERT="${KEY_DIR}/ota_sign_key_cert.pem"

[ -f "$KEY" ] || { echo "ERROR: Key not found: $KEY"; exit 1; }

echo "=== OTA Bundle Signing ==="

MANIFEST="${BUNDLE_DIR}/manifest.json"
echo '{' > "$MANIFEST"
echo '  "format_version": "1.0",' >> "$MANIFEST"
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"," >> "$MANIFEST"
echo "  \"machine\": \"ls1046afrwy\"," >> "$MANIFEST"
echo '  "artifacts": {' >> "$MANIFEST"

FIRST=true
for f in "${BUNDLE_DIR}"/*.wic.bz2 "${BUNDLE_DIR}"/*.itb "${BUNDLE_DIR}"/*.ext4; do
    [ -f "$f" ] || continue
    BASENAME=$(basename "$f")
    HASH=$(sha256sum "$f" | awk '{print $1}')
    SIZE=$(stat -c%s "$f")
    if [ "$FIRST" = true ]; then FIRST=false; else echo ',' >> "$MANIFEST"; fi
    printf '    "%s": {"sha256": "%s", "size": %d}' "$BASENAME" "$HASH" "$SIZE" >> "$MANIFEST"
done

echo '' >> "$MANIFEST"
echo '  }' >> "$MANIFEST"
echo '}' >> "$MANIFEST"

openssl dgst -sha256 -sign "$KEY" -out "${BUNDLE_DIR}/bundle.sig" "$MANIFEST"
openssl dgst -sha256 -verify "$CERT" -signature "${BUNDLE_DIR}/bundle.sig" "$MANIFEST"
echo "=== Bundle ready ==="
