#!/bin/sh

set -xe

export DEBIAN_FRONTEND=noninteractive

# build tools for guest additions
apt-get remove -y --purge build-essential linux-headers-amd64 || true

# clean caches
apt-get autoremove --purge -y
apt-get clean
