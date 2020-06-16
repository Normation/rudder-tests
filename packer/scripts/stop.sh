#!/bin/bash

set -xe

# box is clean
touch /root/clean

# Minimize disk size
dd if=/dev/zero of=/EMPTY bs=1M || true
rm -f /EMPTY
# Block until the empty file has been removed, otherwise, Packer
# will try to kill the box while the disk is still full and that's bad
sync
