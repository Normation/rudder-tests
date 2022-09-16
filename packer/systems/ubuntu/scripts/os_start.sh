#!/bin/sh

set -xe

export DEBIAN_FRONTEND=noninteractive

# keep install up to date
apt-get update
apt-get dist-upgrade -y

# package that should exist everywhere
apt-get -y install zsh vim less curl binutils rsync tree ntp htop dos2unix zip python tree htop ldapscripts lsb-release apt-transport-https dos2unix ca-certificates
apt-get -y install git || apt-get -y install git-core

# machines without the service command will fail here if any
hash service

# build tools for guest additions (install may work without it)
apt-get -y install build-essential linux-headers-amd64 || true

# vim as default
update-alternatives --set editor /usr/bin/vim.basic

# agent dependencies
apt-get -y install uuid-runtime dmidecode cron net-tools diffutils libacl1

