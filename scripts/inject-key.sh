#!/usr/bin/env bash
set -euo pipefail

IMAGE_PATH="${1:-}"
KEY_PATH="${2:-}"
LOOPDEV=""
MOUNT_DIR=""

# Detect if we need sudo (not running as root)
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
    echo "Running as non-root user, will use sudo for privileged operations"
else
    SUDO=""
    echo "Running as root, sudo not needed"
fi

# Check arguments
if [[ -z "$IMAGE_PATH" ]]; then
  echo "Error: No image path provided"
  exit 1
fi
if [[ -z "$KEY_PATH" ]]; then
  echo "Error: No key path provided"
  exit 1
fi

# Attach it as a loop device so Linux treats it like a real disk
LOOPDEV=$($SUDO losetup -f --show "$IMAGE_PATH")

# Get the partition paths
$SUDO partprobe "$LOOPDEV"
ROOT_PART="${LOOPDEV}p2"

# Create temporary mount point
MOUNT_DIR=$(mktemp -d -p /var/tmp)
echo "Using temporary mount point: $MOUNT_DIR"
$SUDO mount --mkdir -t btrfs -o subvol=/var "$ROOT_PART" "$MOUNT_DIR"
