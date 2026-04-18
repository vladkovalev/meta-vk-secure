# Changelog

All notable changes to meta-vk-secure will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] - 2026-04-18

### Added
- Initial release
- NXP Trust Architecture 2.1 support (ISBC/ESBC chain of trust)
- FIT image signing via U-Boot (RSA-2048)
- Shared environment FIT signing
- dm-verity rootfs integrity verification (SHA-256 hash tree)
- LUKS data partition encryption (AES-XTS-256, CAAM ready)
- OTA bundle signature verification (RSA-4096)
- U-Boot secure boot config fragment
- Kernel dm-verity/dm-crypt config fragment
- Key generation script (`scripts/generate-secure-boot-keys.sh`)
- OTA bundle signing script (`scripts/sign-ota-bundle.sh`)
- SRK fuse programming helper (`scripts/program-srk-fuses.sh`)
