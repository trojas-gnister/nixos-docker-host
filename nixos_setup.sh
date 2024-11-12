#!/usr/bin/env bash

# Check if fzf is installed, if not, prompt the user to install it
if ! command -v fzf &> /dev/null; then
  echo "fzf is required but not installed. Please install fzf and try again."
  exit 1
fi

echo "Available storage devices:"
DEVICE=$(lsblk -d -o NAME,SIZE,MODEL | grep -E '^sd|^vd|^nvme' | fzf --prompt="Select a storage device: " | awk '{print $1}')

# Confirm the device input
if [ -z "$DEVICE" ]; then
  echo "No device selected. Exiting."
  exit 1
fi

# Check for existing partitions
if lsblk /dev/$DEVICE | grep -q 'part'; then
  read -p "/dev/$DEVICE already has partitions. Do you want to delete everything and proceed? (yes/no): " CONFIRM
  if [[ "$CONFIRM" != "yes" ]]; then
    echo "Script is unable to proceed due to existing partitions on the device."
    exit 1
  else
    echo "Deleting existing partitions on /dev/$DEVICE..."
    # Use wipefs to remove existing partitions
    wipefs --all /dev/$DEVICE
    sgdisk --zap-all /dev/$DEVICE
  fi
fi

echo "Proceeding to partition /dev/$DEVICE..."

# Automatically create partitions using sgdisk
sgdisk -n 1:0:+512M -t 1:EF00 /dev/$DEVICE  # Boot partition (512 MB, EFI System)
sgdisk -n 2:0:+4G -t 2:8200 /dev/$DEVICE    # Swap partition (4 GB, Linux swap)
sgdisk -n 3:0:0 -t 3:8300 /dev/$DEVICE      # Root partition (remaining space, Linux filesystem)

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

# Replace generated configuration.nix with the preconfigured one from the GitHub repository
echo "Fetching preconfigured configuration.nix from the GitHub repository..."
curl -o /mnt/etc/nixos/configuration.nix https://raw.githubusercontent.com/trojas-gnister/nixos-docker-host/main/configuration.nix

if [ $? -ne 0 ]; then
  echo "Failed to download configuration.nix. Please check the URL and your internet connection."
  exit 1
fi

echo "Preconfigured configuration.nix has been downloaded and replaced."

# Run the installation
echo "Starting NixOS installation..."
sudo nixos-install

if [ $? -eq 0 ]; then
  echo "NixOS installation completed successfully! You can now reboot your system."
else
  echo "NixOS installation encountered an error. Please check the output above for details."
  exit 1
fi
