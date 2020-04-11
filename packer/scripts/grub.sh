#!/bin/bash

set -xe 

echo "GRUB_TIMEOUT=2" >> /etc/default/grub
update-grub

