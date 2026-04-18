# Security overlay for core-image-ota from meta-vk-custom

inherit dm-verity-img

DM_VERITY_IMAGE = "core-image-ota"

IMAGE_INSTALL:append = " \
    cryptsetup \
    data-encryption \
    openssl-bin \
    vk-secure-config \
"

# dm-verity requires read-only rootfs
IMAGE_FEATURES:append = " read-only-rootfs"

# Ensure ext4 is produced for dm-verity hash tree generation
IMAGE_FSTYPES:append = " ext4"