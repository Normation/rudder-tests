#!/bin/sh
set -xe

# package that should exist everywhere
zypper --non-interactive install zsh vim less curl binutils rsync dos2unix zip python lsb-release
zypper --non-interactive install chrony || zypper --non-interactive install ntp
zypper --non-interactive install git-core

# build tools for guest additions (install may work without it)
# vim as default
echo "export VISUAL=/usr/bin/vim" >> ~/.profile

