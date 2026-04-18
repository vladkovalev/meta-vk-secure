# Enable dm-verity, dm-crypt, and crypto in linux-qoriq kernel

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://dm-verity.cfg"
