#!/bin/bash
# Initialize or unlock LUKS-encrypted per-core data partition.
# Production: use CAAM blob encapsulation (uncomment CAAM sections)
# Development: random key at /etc/luks/core<N>.keyblob
set -euo pipefail

log() { logger -t "data-encrypt" "$1"; echo "$1"; }

if [ -f /run/core-role.env ]; then
    . /run/core-role.env
else
    CORE_ID=1
fi

[ -f /etc/ota.conf ] && . /etc/ota.conf

DATA_DEV="${DATA_DEV:-/dev/mmcblk${CORE_ID}p1}"
DATA_MAPPER="data-core${CORE_ID}"
DATA_MOUNT="${DATA_MOUNT:-/data}"
KEYBLOB="/etc/luks/core${CORE_ID}.keyblob"

if [ ! -b "$DATA_DEV" ]; then
    log "Data device $DATA_DEV not found. Skipping."; exit 0
fi

# Key generation (first boot)
if [ ! -f "$KEYBLOB" ]; then
    log "Generating LUKS key for Core ${CORE_ID}"
    mkdir -p /etc/luks && chmod 0700 /etc/luks
    # Production: caam-keygen create "$KEYBLOB" ecb -s 64
    dd if=/dev/urandom of="$KEYBLOB" bs=64 count=1 2>/dev/null
    chmod 0400 "$KEYBLOB"
    log "LUKS key generated (software). Use CAAM in production."
fi

# LUKS format (first boot)
if ! cryptsetup isLuks "$DATA_DEV" 2>/dev/null; then
    log "Formatting LUKS2 on $DATA_DEV"
    cryptsetup luksFormat --batch-mode --type luks2 \
        --cipher aes-xts-plain64 --key-size 512 \
        --hash sha256 --pbkdf pbkdf2 \
        "$DATA_DEV" "$KEYBLOB"
fi

# Unlock
if [ ! -e "/dev/mapper/$DATA_MAPPER" ]; then
    log "Unlocking: $DATA_DEV"
    cryptsetup luksOpen "$DATA_DEV" "$DATA_MAPPER" --key-file "$KEYBLOB"
fi

# Mount
if ! mountpoint -q "$DATA_MOUNT" 2>/dev/null; then
    mkdir -p "$DATA_MOUNT"
    if ! blkid "/dev/mapper/$DATA_MAPPER" 2>/dev/null | grep -q ext4; then
        mkfs.ext4 -L "data-core${CORE_ID}" "/dev/mapper/$DATA_MAPPER"
    fi
    mount "/dev/mapper/$DATA_MAPPER" "$DATA_MOUNT"
    log "Encrypted data mounted at $DATA_MOUNT"
fi
