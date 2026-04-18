#!/bin/bash
# Generate all keys for LS1046A secure boot chain.
# Usage: ./generate-secure-boot-keys.sh [output-directory]
set -euo pipefail

KEY_DIR="${1:-./secure-boot-keys}"
mkdir -p "$KEY_DIR"

echo "=== LS1046A Secure Boot Key Generation ==="
echo "Output: ${KEY_DIR}"
echo ""

# SRK keys (4 for revocation)
echo "--- SRK Keys (RSA-4096 x 4) ---"
for i in 1 2 3 4; do
    if [ ! -f "${KEY_DIR}/SRK${i}_key.pem" ]; then
        openssl genrsa -out "${KEY_DIR}/SRK${i}_key.pem" 4096 2>/dev/null
        openssl req -new -x509 -key "${KEY_DIR}/SRK${i}_key.pem" \
            -out "${KEY_DIR}/SRK${i}_cert.pem" -days 7300 \
            -subj "/CN=LS1046A-SRK${i}/O=VK-Secure"
        echo "  SRK${i}: GENERATED"
    else
        echo "  SRK${i}: exists, skipping"
    fi
done

echo ""
echo "NOTE: Use NXP CST srktool to generate srk_table.bin + srk_fuse.bin"
echo ""

# FIT signing key
echo "--- FIT Signing Key (RSA-2048) ---"
if [ ! -f "${KEY_DIR}/fit_sign_key.pem" ]; then
    openssl genrsa -out "${KEY_DIR}/fit_sign_key.pem" 2048 2>/dev/null
    openssl req -new -x509 -key "${KEY_DIR}/fit_sign_key.pem" \
        -out "${KEY_DIR}/fit_sign_key_cert.pem" -days 3650 \
        -subj "/CN=LS1046A-FIT-Signer/O=VK-Secure"
    ln -sf fit_sign_key.pem "${KEY_DIR}/fit_sign_key.key"
    ln -sf fit_sign_key_cert.pem "${KEY_DIR}/fit_sign_key.crt"
    echo "  fit_sign_key: GENERATED"
else
    echo "  fit_sign_key: exists, skipping"
fi

echo ""

# OTA bundle signing key
echo "--- OTA Bundle Signing Key (RSA-4096) ---"
if [ ! -f "${KEY_DIR}/ota_sign_key.pem" ]; then
    openssl genrsa -out "${KEY_DIR}/ota_sign_key.pem" 4096 2>/dev/null
    openssl req -new -x509 -key "${KEY_DIR}/ota_sign_key.pem" \
        -out "${KEY_DIR}/ota_sign_key_cert.pem" -days 3650 \
        -subj "/CN=LS1046A-OTA-Signer/O=VK-Secure"
    echo "  ota_sign_key: GENERATED"
else
    echo "  ota_sign_key: exists, skipping"
fi

echo ""

# LUKS dev key
echo "--- LUKS Development Key ---"
if [ ! -f "${KEY_DIR}/data_luks_key.bin" ]; then
    dd if=/dev/urandom of="${KEY_DIR}/data_luks_key.bin" bs=64 count=1 2>/dev/null
    chmod 0400 "${KEY_DIR}/data_luks_key.bin"
    echo "  data_luks_key: GENERATED (DEV ONLY)"
else
    echo "  data_luks_key: exists, skipping"
fi

echo ""
echo "=== Done ==="
echo "WARNINGS:"
echo "  1. Store private keys in HSM"
echo "  2. SRK fuse programming is IRREVERSIBLE"
echo "  3. Back up keys"
