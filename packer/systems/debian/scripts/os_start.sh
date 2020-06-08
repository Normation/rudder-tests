#!/bin/sh

set -xe

export DEBIAN_FRONTEND=noninteractive
grep 6.0 /etc/debian_version && EXTRA_OPT="--allow-unauthenticated"

# keep install up to date
apt-get update
apt-get distupgrade

# package that should exist everywhere
apt-get -y ${EXTRA_OPT} install zsh vim less curl binutils rsync tree ntp htop dos2unix zip python tree htop ldapscripts lsb-release apt-transport-https dos2unix
apt-get -y ${EXTRA_OPT} install git || apt-get -y ${EXTRA_OPT} install git-core

# machines without the service command will fail here if any
hash service

# build tools for guest additions (install may work without it)
apt-get install -y ${EXTRA_OPT} build-essential linux-headers-amd64 || true

# vim as default
update-alternatives --set editor /usr/bin/vim.basic

# agent dependencies
apt-get install uuid-runtime dmidecode cron net-tools diffutils libacl1

