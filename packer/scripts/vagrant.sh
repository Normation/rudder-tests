#!/bin/bash

# vagrant connection
mkdir -p /home/vagrant/.ssh
wget --no-check-certificate \
    'https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub' \
    -O /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh
chmod -R go-rwsx /home/vagrant/.ssh

echo "UseDNS no" >> /etc/ssh/sshd_config

# Minimize disk size
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
# Block until the empty file has been removed, otherwise, Packer
# will try to kill the box while the disk is still full and that's bad
sync
