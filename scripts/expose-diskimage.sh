#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-}"

# Check arguments
if [[ -z "$TARGET_DIR" ]]; then
  echo "Error: No directory path provided"
  exit 1
fi

podman run \
  --rm \
  --workdir /srv \
  -p 3003:3003 \
  -v "$TARGET_DIR:/srv:ro" \
  --name bootc-disk-image \
  docker.io/library/python:3-alpine python3 -m http.server 3003
