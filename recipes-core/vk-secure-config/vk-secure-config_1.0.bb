SUMMARY = "VK secure runtime configuration"
DESCRIPTION = "Installs /etc/vk-secure.conf with runtime toggles for security behavior."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# enforce | warn | off
VK_OTA_BUNDLE_VERIFY_MODE ?= "enforce"

do_install() {
    install -d ${D}${sysconfdir}
    cat > ${D}${sysconfdir}/vk-secure.conf <<EOF
# Runtime security toggles
# enforce: block updates if bundle verification fails
# warn:    log failures but allow update
# off:     skip verification entirely (development only)
VK_OTA_BUNDLE_VERIFY_MODE=${VK_OTA_BUNDLE_VERIFY_MODE}
EOF
}

FILES:${PN} = "${sysconfdir}/vk-secure.conf"