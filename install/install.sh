#!/bin/bash
# Main orchestration script for bootc installation
set -euo pipefail

HOSTNAME="${1:-}"
BOOTC_IMAGE="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Usage information
usage() {
    echo "Usage: $0 <hostname> <bootc-image>"
    echo ""
    echo "Example:"
    echo "  $0 server01 quay.io/my-org/my-bootc-image:latest"
    exit 1
}

# Check arguments
if [[ -z "$HOSTNAME" ]] || [[ -z "$BOOTC_IMAGE" ]]; then
    usage
fi

DISK_SCRIPT="${SCRIPT_DIR}/disk/${HOSTNAME}.sh"

# Verify disk script exists
if [[ ! -f "$DISK_SCRIPT" ]]; then
    echo "Error: Disk setup script not found: $DISK_SCRIPT"
    echo ""
    usage
fi

# Verify we're running as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root"
    exit 1
fi

echo "=========================================="
echo "bootc Installation Script"
echo "=========================================="
echo "Hostname:     $HOSTNAME"
echo "Image:        $BOOTC_IMAGE"
echo "Disk script:  $DISK_SCRIPT"
echo "=========================================="
echo ""
read -r -p "Continue with installation? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Install tools
echo ""
echo "==> Step 1/3: Install tools..."
echo ""
pacman -Sy --overwrite "*" podman crun fuse-overlayfs --noconfirm
rm -rf /var/lib/containers/storage
mkdir -p /var/lib/containers

# Mount a 4GB RAM disk directly to Podman's storage directory
mount -t tmpfs -o size=4G tmpfs /var/lib/containers
mkdir -p /var/lib/containers/tmp
export TMPDIR=/var/lib/containers/tmp
export STORAGE_DRIVER=overlay
export STORAGE_OPTS="mount_program=/usr/bin/fuse-overlayfs"

# Run disk setup
echo ""
echo "==> Step 2/3: Running disk setup..."
echo ""

if ! bash "$DISK_SCRIPT"; then
    echo "Error: Disk setup failed"
    exit 1
fi

# Verify /mnt is mounted
if ! mountpoint -q /mnt; then
    echo "Error: /mnt is not mounted. Disk setup may have failed."
    exit 1
fi

# Run bootc install
echo ""
echo "==> Step 3/3: Installing bootc image..."
echo ""

podman pull "$BOOTC_IMAGE"
podman run --rm --privileged --pid=host -it \
    -v /dev:/dev \
    -v /:/target \
    -v /var/lib/containers:/var/lib/containers \
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
    /mnt

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Review the installation"
echo "  2. Run: umount -R /mnt && swapoff -a"
echo "  3. Run: reboot"
echo ""
