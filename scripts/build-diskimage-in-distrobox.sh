#!/usr/bin/env bash
set -euo pipefail

# Wrapper script to run disk image creation in distrobox
# This ensures all dependencies are available in an FHS-compliant environment

CONTAINER_NAME="bootc-arch-desktop-builder"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_PATH="${1:-}"

# Color output for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${GREEN}==> $1${NC}"
}

warn() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

# Check arguments
if [[ -z "$IMAGE_PATH" ]]; then
    error "No image path provided\nUsage: $0 <output-image-path>"
fi

# Convert to absolute path
IMAGE_PATH=$(realpath "$IMAGE_PATH")
IMAGE_DIR=$(dirname "$IMAGE_PATH")

# Ensure output directory exists
if [[ ! -d "$IMAGE_DIR" ]]; then
    error "Output directory does not exist: $IMAGE_DIR"
fi

# Check if distrobox is available
if ! command -v distrobox &> /dev/null; then
    error "distrobox is not installed. Please install it first."
fi

# Check if container exists
if ! distrobox list --root 2>/dev/null | grep -q "^$CONTAINER_NAME"; then
    info "Container '$CONTAINER_NAME' not found. Creating from distrobox.ini..."

    if [[ ! -f "$PROJECT_ROOT/distrobox.ini" ]]; then
        error "distrobox.ini not found at $PROJECT_ROOT/distrobox.ini"
    fi

    cd "$PROJECT_ROOT"
    if ! distrobox assemble create --file distrobox.ini; then
        error "Failed to create distrobox container"
    fi

    info "Container created successfully"
fi

# Pass through BOOTC_IMAGE environment variable if set
BOOTC_IMAGE_ARG=""
if [[ -n "${BOOTC_IMAGE:-}" ]]; then
    BOOTC_IMAGE_ARG="--env BOOTC_IMAGE=$BOOTC_IMAGE"
    info "Using bootc image: $BOOTC_IMAGE"
fi

# Run the disk creation script inside container
info "Running disk image creation in container '$CONTAINER_NAME'..."
info "Output will be: $IMAGE_PATH"

# Execute in distrobox with proper environment
if distrobox enter --root $BOOTC_IMAGE_ARG "$CONTAINER_NAME" -- \
    bash "$PROJECT_ROOT/scripts/make-diskimage.sh" "$IMAGE_PATH"; then
    info "Disk image created successfully: $IMAGE_PATH"
else
    error "Disk image creation failed"
fi
