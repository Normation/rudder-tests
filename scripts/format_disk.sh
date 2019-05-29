#!/bin/bash
set -x
PORT="$1"
ALPHABET=( {a..z} )
LETTER_ID=$(echo ${ALPHABET[$PORT]})
(
echo o # Create a new empty DOS partition table
echo n # Add a new partition
echo p # Primary partition
echo 1 # Partition number
echo   # First sector (Accept default: 1)
echo   # Last sector (Accept default: varies)
echo w # Write changes
) | sudo fdisk /dev/sd${LETTER_ID}
mkdir -p /srv
sudo mkfs.ext4 /dev/sd${LETTER_ID}1
sudo mount /dev/sd${LETTER_ID}1 /srv
