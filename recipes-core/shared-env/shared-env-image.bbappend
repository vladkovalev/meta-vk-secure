# Add FIT signing to shared-env.itb build from meta-vk-custom

DEPENDS += "openssl-native"

do_compile:append() {
    cd ${B}

    if [ -f "${FIT_SIGN_KEYDIR}/${FIT_SIGN_KEYNAME}.key" ] || \
       [ -f "${FIT_SIGN_KEYDIR}/${FIT_SIGN_KEYNAME}.pem" ]; then
        bbnote "Signing shared-env.itb with ${FIT_SIGN_KEYNAME}"
        mkimage -F \
            -k ${FIT_SIGN_KEYDIR} \
            -K shared-env.dtb \
            -r shared-env.itb
        bbnote "Shared env FIT signed successfully."
    else
        bbwarn "FIT signing key not found. Shared env will NOT be signed."
    fi
}
