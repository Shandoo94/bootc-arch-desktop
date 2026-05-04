#!/usr/bin/env bash
set -euo pipefail

IMAGE_PATH="${1:-}"
KEY_PATH="${2:-}"
SECRETS_PATH="${3:-}"
SECRETS_KEY="${4:-}"
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
    echo "Unmounting filesystem..."
    $SUDO umount "$MOUNT_DIR" 2>/dev/null || true
    rmdir "$MOUNT_DIR" 2>/dev/null || true
  fi
  if [ -n "${LOOPDEV:-}" ]; then
    echo "Detaching loop device $LOOPDEV..."
    $SUDO losetup -d "$LOOPDEV" 2>/dev/null || true
  fi
  echo "Cleanup complete"
}
trap cleanup EXIT

# Check for required dependencies
for cmd in sops yq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: Required command '$cmd' not found"
    exit 1
  fi
done

# Check arguments
if [[ -z "$IMAGE_PATH" ]]; then
  echo "Error: No image path provided"
  echo "Usage: $0 <image_path> <key_path> <secrets_path> <secrets_key>"
  echo "  image_path:   Path to the disk image file"
  echo "  key_path:     Destination path for the key relative to /var (e.g., lib/sops/age/key.txt)"
  echo "  secrets_path: Path to the SOPS-encrypted secrets YAML file"
  echo "  secrets_key:  YAML key path to extract (e.g., atlas.age_key)"
  exit 1
fi
if [[ -z "$KEY_PATH" ]]; then
  echo "Error: No key path provided"
  exit 1
fi
if [[ -z "$SECRETS_PATH" ]]; then
  echo "Error: No path for sops encrypted secrets provided"
  exit 1
fi
if [[ -z "$SECRETS_KEY" ]]; then
  echo "Error: No yaml key for secret provided"
  exit 1
fi

# Validate that files exist
if [[ ! -f "$IMAGE_PATH" ]]; then
  echo "Error: Image file not found: $IMAGE_PATH"
  exit 1
fi
if [[ ! -f "$SECRETS_PATH" ]]; then
  echo "Error: Secrets file not found: $SECRETS_PATH"
  exit 1
fi

# Attach it as a loop device so Linux treats it like a real disk
echo "Attaching disk image as loop device..."
LOOPDEV=$($SUDO losetup -f --show "$IMAGE_PATH")
echo "Loop device: $LOOPDEV"

# Get the partition paths
$SUDO partprobe "$LOOPDEV"
ROOT_PART="${LOOPDEV}p2"

# Create temporary mount point
MOUNT_DIR=$(mktemp -d -p /var/tmp)
echo "Using temporary mount point: $MOUNT_DIR"
$SUDO mount -t btrfs -o subvol=/root "$ROOT_PART" "$MOUNT_DIR"

# Create parent directories for the key
KEY_DEST="$MOUNT_DIR/state/os/default/var/$KEY_PATH"
KEY_DIR=$(dirname "$KEY_DEST")
echo "Creating directory: $KEY_DIR"
$SUDO mkdir -p "$KEY_DIR"

# Decrypt the secrets file, extract the key value, and write directly to destination
# The key is kept in memory only - no intermediate files are created
echo "Extracting and writing key to disk image..."
sops -d "$SECRETS_PATH" | yq -r ".$SECRETS_KEY" | $SUDO tee "$KEY_DEST" > /dev/null

# Verify the key was written (check it's not empty or "null")
if [[ ! -s "$KEY_DEST" ]] || [[ "$($SUDO cat "$KEY_DEST")" == "null" ]]; then
  echo "Error: Failed to extract key '$SECRETS_KEY' from secrets file"
  echo "The key may not exist or the value is empty"
  $SUDO rm -f "$KEY_DEST"
  exit 1
fi

# Set proper ownership and permissions (root:root, read-only by root)
echo "Setting file permissions..."
$SUDO chown root:root "$KEY_DEST"
$SUDO chmod 0400 "$KEY_DEST"

echo "Key successfully injected to /var/$KEY_PATH"
echo "Permissions: 0400 (root read-only)"
