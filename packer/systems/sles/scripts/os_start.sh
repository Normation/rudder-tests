#!/bin/sh
set -xe

# package that should exist everywhere
zypper --non-interactive install zsh vim less curl binutils rsync tree ntp htop dos2unix zip python tree htop ldapscripts lsb-release dos2unix
zypper --non-interactive git-core

# build tools for guest additions (install may work without it)

# vim as default
echo "export VISUAL=/usr/bin/vim" >> ~/.profile

