#!/bin/bash
set -euo pipefail

# Disks
DISK_ONE="/dev/vda"

# Partitioning
parted -s $DISK_ONE mklabel gpt
parted -s $DISK_ONE mkpart ESP fat32 1MiB 1GiB
parted -s $DISK_ONE set 1 esp on
parted -s $DISK_ONE mkpart swap linux-swap 1GiB 3GiB
parted -s $DISK_ONE mkpart pool 3GiB 100%

# Format boot
mkfs.fat -F 32 "${DISK_ONE}1"

# Make swap
mkswap "${DISK_ONE}2"

# Make btrfs root
mkfs.btrfs -f -L poolfs "${DISK_ONE}3"

# Mount and create subvolumes
mkdir -p /mnt
mount -t btrfs -o subvol=/ "${DISK_ONE}3" /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/var
umount /mnt

# Remount with subvolumes
mount -t btrfs -o subvol=/root "${DISK_ONE}3" /mnt
mount --mkdir -t btrfs -o subvol=/var "${DISK_ONE}3" /mnt/var
mount --mkdir "${DISK_ONE}1" /mnt/boot
swapon "${DISK_ONE}2"
