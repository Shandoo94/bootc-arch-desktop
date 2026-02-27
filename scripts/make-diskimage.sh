#!/usr/bin/env bash
set -euo pipefail

IMAGE_PATH="${1:-}"
BOOTC_IMAGE="${BOOTC_IMAGE:-ghcr.io/shandoo94/bootc-arch-desktop:latest}"
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

# Cleanup function - always unmount and detach
cleanup() {
  echo "Cleaning up..."
  if [ -n "${MOUNT_DIR:-}" ] && [ -d "$MOUNT_DIR" ]; then
    echo "Unmounting filesystems..."
    $SUDO umount -R "$MOUNT_DIR" 2>/dev/null || true
    rmdir "$MOUNT_DIR" 2>/dev/null || true
  fi
  if [ -n "${LOOPDEV:-}" ]; then
    echo "Detaching loop device $LOOPDEV..."
    $SUDO losetup -d "$LOOPDEV" 2>/dev/null || true
  fi
  echo "Cleanup complete"
}
trap cleanup EXIT

# Check arguments
if [[ -z "$IMAGE_PATH" ]]; then
  echo "Error: No image path provided"
  exit 1
fi

# Create a blank file (this will be our virtual hard drive)
truncate -s 8G "$IMAGE_PATH"

# Attach it as a loop device so Linux treats it like a real disk
LOOPDEV=$($SUDO losetup -f --show "$IMAGE_PATH")

# Partitioning
$SUDO parted -s "$LOOPDEV" mklabel gpt
$SUDO parted -s "$LOOPDEV" mkpart ESP fat32 1MiB 1GiB
$SUDO parted -s "$LOOPDEV" set 1 esp on
$SUDO parted -s "$LOOPDEV" mkpart pool 1GiB 100%

# Get the partition paths
$SUDO partprobe "$LOOPDEV"
EFI_PART="${LOOPDEV}p1"
ROOT_PART="${LOOPDEV}p2"

# Format partitions
$SUDO mkfs.fat -F 32 "$EFI_PART"
$SUDO mkfs.btrfs -f -L poolfs "$ROOT_PART"

# Create temporary mount point
MOUNT_DIR=$(mktemp -d -p /var/tmp)
echo "Using temporary mount point: $MOUNT_DIR"

# Mount and create subvolumes
$SUDO mount -t btrfs -o subvol=/ "$ROOT_PART" "$MOUNT_DIR"
$SUDO btrfs subvolume create "$MOUNT_DIR/root"
$SUDO btrfs subvolume create "$MOUNT_DIR/var"
$SUDO umount "$MOUNT_DIR"

# Remount in correct layout for installation
$SUDO mount -t btrfs -o subvol=/root "$ROOT_PART" "$MOUNT_DIR"
$SUDO mount --mkdir -t btrfs -o subvol=/var "$ROOT_PART" "$MOUNT_DIR/var"
$SUDO mount --mkdir "$EFI_PART" "$MOUNT_DIR/boot"

# Run installation
$SUDO podman run --rm --privileged --pid=host \
    -v /dev:/dev \
    -v /:/target \
    -v /var/lib/containers:/var/lib/containers \
    -v "$MOUNT_DIR:$MOUNT_DIR:rslave" \
    --security-opt label=type:unconfined_t \
    -e RUST_LOG=debug \
    "$BOOTC_IMAGE" \
    bootc install to-filesystem \
    --target-no-signature-verification \
    --karg=root=LABEL=poolfs \
    --karg=rootflags=compress=zstd,noatime,subvol=/root \
    --karg="systemd.mount_extra=LABEL=poolfs:/var:btrfs:compress=zstd,noatime,subvol=/var" \
    --karg=rw \
    --composefs-backend \
    --disable-selinux \
    --bootloader systemd \
    "$MOUNT_DIR"

echo "Installation complete. Disk image created at: $IMAGE_PATH"
