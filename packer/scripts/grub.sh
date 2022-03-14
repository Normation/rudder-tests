#!/bin/bash

set -xe

if command -v update-grub &> /dev/null
then
  echo "GRUB_TIMEOUT=2" >> /etc/default/grub
  update-grub || grub2-mkconfig -o /boot/grub2/grub.cfg
else
  echo "No grub install found, skipping..."
fi

