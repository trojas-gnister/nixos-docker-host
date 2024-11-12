#!/bin/bash

echo "Available storage devices:"
lsblk -d -o NAME,SIZE,MODEL | grep -E '^sd|^vd|^nvme'

read -p "Enter the target device (e.g., sda, vda, nvme0n1): " DEVICE

# Confirm the device input
if [ ! -b "/dev/$DEVICE" ]; then
  echo "Error: /dev/$DEVICE is not a valid block device."
  exit 1
fi

echo "Proceeding to partition /dev/$DEVICE..."

# Use cfdisk for partitioning
cfdisk /dev/$DEVICE

# Confirm partition layout with the user
read -p "Ensure partitions are created as follows:
1. Boot (512 MB, EFI System)
2. Swap (4 GB, Linux swap)
3. Root (remaining space, Linux filesystem)
Press Enter to continue if partitions are correct, or Ctrl+C to cancel."

# Format partitions
echo "Formatting partitions..."

mkfs.fat -F 32 /dev/${DEVICE}1  # Boot partition
mkswap /dev/${DEVICE}2          # Swap partition
mkfs.ext4 /dev/${DEVICE}3       # Root partition

# Mount partitions
echo "Mounting partitions..."

mount /dev/${DEVICE}3 /mnt
mkdir -p /mnt/boot
mount /dev/${DEVICE}1 /mnt/boot
swapon /dev/${DEVICE}2

echo "Generating NixOS configuration..."
nixos-generate-config --root /mnt

echo "Done! The partitions have been set up and mounted. You can now edit /mnt/etc/nixos/configuration.nix and proceed with the installation using 'nixos-install'."
