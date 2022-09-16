#!/bin/bash

set -xe

BASE="/home/vagrant"
MNT="/tmp/isoVbx"
VBX_VERSION=$(cat "${BASE}/.vbox_version")

# sles refuses virtualbx modules by default
sed -i -e 's/^allow_unsupported_modules 0/allow_unsupported_modules 1/' /etc/modprobe.d/10-unsupported-modules.conf || true

mkdir -p "${MNT}"
mount -t iso9660 -o loop "${BASE}/VBoxGuestAdditions_${VBX_VERSION}.iso" "${MNT}"

# a bug makes it always return 2
${MNT}/VBoxLinuxAdditions.run --nox11 || true

umount ${MNT}
rm -rf ${MNT} ${BASE}/VBoxGuestAdditions_${VBX_VERSION}.iso
cat /var/log/vbox*
VBoxService -V
