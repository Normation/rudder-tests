#!/bin/bash
set -x

BASE="/home/vagrant"
MNT="/tmp/isoVbx"
VBX_VERSION=$(cat "${BASE}/.vbox_version")

sed -i -e 's/^allow_unsupported_modules 0/allow_unsupported_modules 1/' /etc/modprobe.d/10-unsupported-modules.conf

mkdir -p "${MNT}"
mount -t iso9660 -o loop "${BASE}/VBoxGuestAdditions_${VBX_VERSION}.iso" "${MNT}"

${MNT}/VBoxLinuxAdditions.run --nox11

umount ${MNT}
rm -rf ${MNT} ${BASE}/VBoxGuestAdditions_${VBX_VERSION}.iso
