## Change Description: OTA Bundle Verification Bypass (Runtime-Configurable)

### Summary
This change introduces a **runtime-controlled bypass mechanism for OTA bundle verification** while keeping **secure boot / FIT signature enforcement unchanged** (still required). The goal is to support development workflows where OTA bundles may be unsigned or incomplete, without weakening the boot-time trust chain.

---

### What Changed

#### 1) OTA bundle verification now supports 3 runtime modes
A new runtime setting `VK_OTA_BUNDLE_VERIFY_MODE` controls how the device reacts to OTA bundle verification failures:

- `enforce` (default): **strict** — verification failures block the update (`exit 1`)
- `warn`: **bypass** — verification failures are logged, but update is allowed (`exit 0`)
- `off`: **skip verification** entirely and allow update (`exit 0`)  
  *(intended for development only)*

---

#### 2) New config file on target: `/etc/vk-secure.conf`
A new recipe installs `/etc/vk-secure.conf`, which contains runtime security toggles such as:

- `VK_OTA_BUNDLE_VERIFY_MODE=enforce|warn|off`

This allows switching between strict and bypass behavior **without rebuilding firmware**, by editing a file on the target.

You can also set the value at build time, e.g. in `local.conf`:
- `VK_OTA_BUNDLE_VERIFY_MODE = "warn"`

---

#### 3) Patched `ota-verify-bundle.sh` to honor runtime mode
`ota-verify-bundle.sh` was updated to:

- Read `/etc/vk-secure.conf`
- Apply behavior based on `VK_OTA_BUNDLE_VERIFY_MODE`
- Use a unified helper `reject_or_warn()` to:
  - reject update in `enforce`
  - allow update in `warn`
  - skip verification in `off`

This ensures consistent behavior across all verification failure paths.

---

#### 4) Image update: include the new config recipe
`core-image-ota.bbappend` was updated to include `vk-secure-config` in `IMAGE_INSTALL`, so that `/etc/vk-secure.conf` is always present on the target.

---

### What Did NOT Change (Important)
- **U-Boot FIT signature requirement remains enforced.**
- Secure boot / chain-of-trust and fuse programming behavior are **not affected**.
- This change only impacts **user-space OTA bundle verification** (manifest signature + artifact hashes).

---

### Files Added / Modified

#### Modified
- `meta-vk-secure/recipes-core/ota-update-agent/files/ota-verify-bundle.sh`  
  (adds runtime mode support and bypass behavior)
- `meta-vk-secure/recipes-core/images/core-image-ota.bbappend`  
  (adds `vk-secure-config` package to the image)

#### Added
- `meta-vk-secure/recipes-core/vk-secure-config/vk-secure-config_1.0.bb`  
  (installs `/etc/vk-secure.conf`)

---

### Rationale / Benefit
This change allows development teams to:
- Test update flows without being blocked by bundle signing tooling
- Still keep boot-time security strict (signed FIT required)
- Transition smoothly to production by setting mode back to `enforce`
# Changelog

## [1.0.0] - 2026-04-18

### Added
- Initial release
- NXP Trust Architecture 2.1 support (ISBC/ESBC chain of trust)
- FIT image signing via U-Boot (RSA-2048)
- Shared environment FIT signing
- dm-verity rootfs integrity verification (SHA-256 hash tree)
- LUKS data partition encryption (AES-XTS-256, CAAM ready)
- OTA bundle signature verification (RSA-4096)
- Key generation script
- OTA bundle signing script
- SRK fuse programming helper
