# meta-vk-secure

**Proprietary** security layer for LS1046A multi-core OTA systems.
Overlays [meta-vk-custom](https://github.com/vladkovalev/meta-vk-custom)
with hardware-rooted secure boot, integrity verification, and encryption.

> This repository is confidential. Do not share outside your organization
> without written authorization.

## Features

| Feature | Mechanism | Protects Against |
|---|---|---|
| NXP Chain of Trust | ISBC/ESBC via SRK fuses | Tampered bootloader |
| FIT image signing | RSA-2048, key in U-Boot DTB | Modified kernel/DTB/initramfs |
| Shared env signing | Signed FIT container | Role/slot manipulation |
| dm-verity | SHA-256 hash tree on rootfs | Rootfs modification |
| LUKS encryption | AES-XTS-256 (CAAM ready) | Data extraction from flash |
| OTA bundle verification | RSA-4096 manifest signature | Malicious OTA updates |
| U-Boot lockdown | Console password (optional) | Physical access attacks |
| Key revocation | 4x SRK fuse slots | Compromised signing key |

## Quick Start

### 1. Generate keys (one-time, offline)

    chmod +x meta-vk-secure/scripts/generate-secure-boot-keys.sh
    ./meta-vk-secure/scripts/generate-secure-boot-keys.sh /path/to/secure-boot-keys

### 2. Configure build

    bitbake-layers add-layer /path/to/meta-vk-secure
    echo 'require conf/machine/ls1046a-fitimage.inc' >> conf/local.conf
    echo 'require conf/machine/ls1046a-secure.inc' >> conf/local.conf
    echo 'SECURE_BOOT_KEYDIR = "/path/to/secure-boot-keys"' >> conf/local.conf

### 3. Build

    bitbake core-image-ota

## Architecture

    meta-vk-custom (priority 6)          meta-vk-secure (priority 8)
    core-image-ota.bb            <---    core-image-ota.bbappend
                                           +dm-verity +cryptsetup +read-only-rootfs
    shared-env-image.bb          <---    shared-env-image.bbappend
                                           +FIT signing step
    ota-update-agent.bb          <---    ota-update-agent.bbappend
                                           +bundle signature verification
                                          u-boot-qoriq_%.bbappend
                                           +secure-boot.cfg +embedded signing key
                                          linux-qoriq_%.bbappend
                                           +dm-verity.cfg +dm-crypt.cfg
                                          data-encryption_1.0.bb
                                           LUKS init/unlock service

## Warnings

- SRK fuse programming is IRREVERSIBLE
- Keep 2 SRK slots reserved for key rotation
- Back up all private keys
- Use CAAM blob encapsulation in production
