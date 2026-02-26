set -euo pipefail

IMAGE_PATH="${1:-}"
LOOPDEV=""
MOUNT_DIR=""

# Cleanup function - always unmount and detach
cleanup() {
  echo "Cleaning up..."
  if [ -n "${MOUNT_DIR:-}" ] && [ -d "$MOUNT_DIR" ]; then
    echo "Unmounting filesystems..."
    sudo umount -R "$MOUNT_DIR" 2>/dev/null || true
    rmdir "$MOUNT_DIR" 2>/dev/null || true
  fi
  if [ -n "${LOOPDEV:-}" ]; then
    echo "Detaching loop device $LOOPDEV..."
    sudo losetup -d "$LOOPDEV" 2>/dev/null || true
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
LOOPDEV=$(sudo losetup -f --show "$IMAGE_PATH")

# Partitioning
sudo parted -s "$LOOPDEV" mklabel gpt
sudo parted -s "$LOOPDEV" mkpart ESP fat32 1MiB 1GiB
sudo parted -s "$LOOPDEV" set 1 esp on
sudo parted -s "$LOOPDEV" mkpart pool 1GiB 100%

# Get the partition paths
sudo partprobe "$LOOPDEV"
EFI_PART="${LOOPDEV}p1"
ROOT_PART="${LOOPDEV}p2"

# Format partitions
sudo mkfs.fat -F 32 "$EFI_PART"
sudo mkfs.btrfs -f -L poolfs "$ROOT_PART"

# Create temporary mount point
MOUNT_DIR=$(mktemp -d)
echo "Using temporary mount point: $MOUNT_DIR"

# Mount and create subvolumes
sudo mount -t btrfs -o subvol=/ "$ROOT_PART" "$MOUNT_DIR"
sudo btrfs subvolume create "$MOUNT_DIR/root"
sudo btrfs subvolume create "$MOUNT_DIR/var"
sudo umount "$MOUNT_DIR"

# Remount in correct layout for installation
sudo mount -t btrfs -o subvol=/root "$ROOT_PART" "$MOUNT_DIR"
sudo mount --mkdir -t btrfs -o subvol=/var "$ROOT_PART" "$MOUNT_DIR/var"
sudo mount --mkdir "$EFI_PART" "$MOUNT_DIR/boot"

# Run installation
sudo podman run --rm --privileged --pid=host -it \
    -v /dev:/dev \
    -v /:/target \
    -v /var/lib/containers:/var/lib/containers \
    --security-opt label=type:unconfined_t \
    -e RUST_LOG=debug \
    ghcr.io/shandoo94/bootc-arch-desktop:latest \
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
