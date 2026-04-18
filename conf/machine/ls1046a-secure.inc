# LS1046A Security Configuration
# Include in local.conf: require conf/machine/ls1046a-secure.inc

# Key paths (override in local.conf or CI environment)
SECURE_BOOT_KEYDIR ?= "${TOPDIR}/secure-boot-keys"
FIT_SIGN_KEYDIR ?= "${SECURE_BOOT_KEYDIR}"
FIT_SIGN_KEYNAME ?= "fit_sign_key"
OTA_SIGN_KEYDIR ?= "${SECURE_BOOT_KEYDIR}"
OTA_SIGN_KEYNAME ?= "ota_sign_key"

# U-Boot FIT signature verification
UBOOT_SIGN_ENABLE = "1"
UBOOT_SIGN_KEYDIR = "${FIT_SIGN_KEYDIR}"
UBOOT_SIGN_KEYNAME = "${FIT_SIGN_KEYNAME}"
UBOOT_SIGN_IMG_KEYNAME = "${FIT_SIGN_KEYNAME}"
UBOOT_MKIMAGE_SIGN_ARGS = "-E -p 0x1000"
FIT_SIGN_INDIVIDUAL = "1"

# dm-verity
DM_VERITY_IMAGE_TYPE = "ext4"

# Feature flag
VK_SECURE_BOOT_ENABLED = "1"
