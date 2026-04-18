SUMMARY = "LUKS encryption for per-core data partitions"
DESCRIPTION = "Systemd service that initializes or unlocks LUKS-encrypted \
per-core data partitions. Supports NXP CAAM hardware key derivation."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://data-encrypt-init.sh \
    file://data-encrypt-init.service \
"

RDEPENDS:${PN} = "cryptsetup bash util-linux e2fsprogs core-role-manager"

inherit systemd

SYSTEMD_SERVICE:${PN} = "data-encrypt-init.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/data-encrypt-init.sh ${D}${bindir}/data-encrypt-init

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/data-encrypt-init.service ${D}${systemd_system_unitdir}/

    install -d ${D}${sysconfdir}/luks
}

FILES:${PN} += "${sysconfdir}/luks"
