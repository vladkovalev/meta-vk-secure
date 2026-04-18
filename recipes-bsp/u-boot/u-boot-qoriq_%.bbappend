# Inject secure boot config and FIT signing public key into U-Boot

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://secure-boot.cfg"

UBOOT_SIGN_ENABLE = "1"
UBOOT_SIGN_KEYDIR = "${FIT_SIGN_KEYDIR}"
UBOOT_SIGN_KEYNAME = "${FIT_SIGN_KEYNAME}"
UBOOT_SIGN_IMG_KEYNAME = "${FIT_SIGN_KEYNAME}"
UBOOT_MKIMAGE_SIGN_ARGS = "-E -p 0x1000"
