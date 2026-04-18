# Add OTA bundle signature verification to update agent

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://ota-verify-bundle.sh"

RDEPENDS:${PN} += "openssl-bin"

do_install:append() {
    install -m 0755 ${WORKDIR}/ota-verify-bundle.sh ${D}${bindir}/ota-verify-bundle

    install -d ${D}${sysconfdir}/ota
    if [ -f "${OTA_SIGN_KEYDIR}/${OTA_SIGN_KEYNAME}_cert.pem" ]; then
        install -m 0644 "${OTA_SIGN_KEYDIR}/${OTA_SIGN_KEYNAME}_cert.pem" \
            ${D}${sysconfdir}/ota/ota_sign_cert.pem
    else
        bbwarn "OTA signing cert not found. Creating placeholder."
        touch ${D}${sysconfdir}/ota/ota_sign_cert.pem
    fi
}

FILES:${PN} += "${sysconfdir}/ota"
