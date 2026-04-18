# Security overlay for core-image-ota from meta-vk-custom

inherit dm-verity-img

DM_VERITY_IMAGE = "core-image-ota"

IMAGE_INSTALL:append = " \
    cryptsetup \
    data-encryption \
    openssl-bin \
"

IMAGE_FEATURES:append = " read-only-rootfs"
IMAGE_FSTYPES:append = " ext4"
