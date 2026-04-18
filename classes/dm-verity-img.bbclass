# Generates dm-verity hash tree and root hash for rootfs images.
#
# Usage: inherit dm-verity-img
#        DM_VERITY_IMAGE = "core-image-ota"

DM_VERITY_HASH_BLOCK_SIZE ?= "4096"
DM_VERITY_DATA_BLOCK_SIZE ?= "4096"

DEPENDS += "cryptsetup-native"

dm_verity_create() {
    local IMAGE="${IMGDEPLOYDIR}/${IMAGE_NAME}.rootfs.ext4"

    if [ ! -f "$IMAGE" ]; then
        bbwarn "dm-verity: rootfs ext4 not found at ${IMAGE}, skipping."
        return
    fi

    local ROOTHASH="${IMAGE}.roothash"
    local HASHTREE="${IMAGE}.hashtree"
    local VERITYLOG="${IMAGE}.verity.log"

    bbnote "dm-verity: generating hash tree for ${IMAGE}"

    veritysetup format \
        --data-block-size=${DM_VERITY_DATA_BLOCK_SIZE} \
        --hash-block-size=${DM_VERITY_HASH_BLOCK_SIZE} \
        "${IMAGE}" "${HASHTREE}" | tee "${VERITYLOG}"

    grep "Root hash:" "${VERITYLOG}" | awk '{print $3}' > "${ROOTHASH}"
    grep "Salt:" "${VERITYLOG}" | awk '{print $2}' > "${IMAGE}.veritysalt"
    grep "Data blocks:" "${VERITYLOG}" | awk '{print $3}' > "${IMAGE}.verityblocks"
    grep "Hash algorithm:" "${VERITYLOG}" | awk '{print $3}' > "${IMAGE}.verityalgo"

    bbnote "dm-verity root hash: $(cat ${ROOTHASH})"

    cat "${HASHTREE}" >> "${IMAGE}"
    rm -f "${HASHTREE}"

    bbnote "dm-verity: hash tree appended to ${IMAGE}"
}

IMAGE_POSTPROCESS_COMMAND += "dm_verity_create;"
