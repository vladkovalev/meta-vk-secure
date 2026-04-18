# meta-vk-secure

**Proprietary** security layer for LS1046A multi-core OTA systems.
Overlays [meta-vk-custom](https://github.com/vladkovalev/meta-vk-custom)
with hardware-rooted secure boot, integrity verification, and encryption.

> ⚠️ This repository is confidential. Do not share outside your organization
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
| Key revocation | 4× SRK fuse slots | Compromised signing key |

## Prerequisites

- [meta-vk-custom](https://github.com/vladkovalev/meta-vk-custom) — OTA layer
- [meta-freescale](https://github.com/Freescale/meta-freescale) — NXP BSP (scarthgap)
- [poky](https://git.yoctoproject.org/poky) — Yocto core (scarthgap)
- [meta-openembedded](https://git.openembedded.org/meta-openembedded) — meta-oe, meta-python, meta-networking

## Quick Start

### 1. Generate keys (one-time, offline)

```bash
chmod +x meta-vk-secure/scripts/generate-secure-boot-keys.sh
./meta-vk-secure/scripts/generate-secure-boot-keys.sh /path/to/secure-boot-keys

# Store private keys in HSM/vault — NEVER commit to git
```

### 2. Configure build

```bash
# Add layers
bitbake-layers add-layer /path/to/meta-vk-secure

# Add to conf/local.conf:
echo 'require conf/machine/ls1046a-fitimage.inc' >> conf/local.conf
echo 'require conf/machine/ls1046a-secure.inc' >> conf/local.conf
echo 'SECURE_BOOT_KEYDIR = "/path/to/secure-boot-keys"' >> conf/local.conf
```

### 3. Build

```bash
bitbake core-image-ota
```

### 4. Sign OTA bundle

```bash
mkdir ota-bundle
cp tmp/deploy/images/ls1046afrwy/core-image-ota-ls1046afrwy.wic.bz2 ota-bundle/rootfs.wic.bz2
cp tmp/deploy/images/ls1046afrwy/fitImage ota-bundle/kernel.itb
cp tmp/deploy/images/ls1046afrwy/shared-env.itb ota-bundle/

./meta-vk-secure/scripts/sign-ota-bundle.sh ota-bundle /path/to/secure-boot-keys
```

## Architecture

When this layer is present in `bblayers.conf`, bbappends automatically overlay
security onto `meta-vk-custom` recipes:

```
meta-vk-custom (priority 6)          meta-vk-secure (priority 8)
────────────────────────              ────────────────────────────
core-image-ota.bb            ←───    core-image-ota.bbappend
  (rootfs image)                       +dm-verity
                                       +cryptsetup
                                       +read-only-rootfs

shared-env-image.bb          ←───    shared-env-image.bbappend
  (builds FIT)                         +FIT signing step

ota-update-agent.bb           ←───    ota-update-agent.bbappend
  (writes images)                      +bundle signature verification

(no u-boot recipe)                    u-boot-qoriq_%.bbappend
                                       +secure-boot.cfg
                                       +embedded FIT signing public key

(no kernel recipe)                    linux-qoriq_%.bbappend
                                       +dm-verity.cfg
                                       +dm-crypt.cfg

                                      data-encryption_1.0.bb
                                       LUKS init/unlock service
```

### Without meta-vk-secure

```bash
bitbake-layers remove-layer meta-vk-secure
bitbake core-image-ota
# → unsigned FIT, rw rootfs, plain data partition
# → fully functional, just not secured
```

## Key Hierarchy

```
OTPMK (fused in SoC, hardware)
  └── SRK hash (fused, 4 key slots for revocation)
        └── SRK key pairs (RSA-4096, signs ISBC/ESBC)
              └── FIT signing key (RSA-2048, signs kernel FIT + shared-env)
              └── OTA signing key (RSA-4096, signs update bundles)
  └── CAAM blob key (derived from OTPMK, encrypts LUKS keyblob)
```

## SRK Fuse Programming

**⚠️ IRREVERSIBLE** — Read `scripts/program-srk-fuses.sh` carefully.

1. Generate SRK table with NXP CST tool
2. Test on development board with non-production fuses
3. Verify secure boot works end-to-end
4. Only then program production units
5. Keep 2 SRK slots reserved for key rotation

## Compliance

This layer supports:
- **IEC 62443** — Industrial security (secure boot, integrity)
- **ISO 27001** — Information security (key management, audit trail)
- **NIST SP 800-193** — Platform firmware resiliency
- **Automotive SPICE** — Separated security artifacts with independent versioning

## Support

For security patches, key rotation procedures, or compliance documentation,
contact your account representative.

## Version History

See [CHANGELOG.md](CHANGELOG.md).
