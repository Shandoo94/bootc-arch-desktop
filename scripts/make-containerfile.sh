#!/usr/bin/env bash
set -euo pipefail

# Allow hostname to be passed as first argument, or use all hosts from inventory
HOSTNAME_INPUT="${1:-}"
GIT_SHA="${GIT_SHA:-$(git rev-parse HEAD 2>/dev/null || echo "unknown")}"
BASE_IMAGE_REF="${BASE_IMAGE_REF:-$(head -n1 base-image.lock | tr -d '[:space:]')}"
BUILD_DATE="${BUILD_DATE:-local}"
BUILD_NUMBER="${BUILD_NUMBER:-dev}"

if [ -n "${HOSTNAME_INPUT}" ]; then
  # Single host mode - generate for specified hostname only
  HOSTNAMES="${HOSTNAME_INPUT}"
else
  # Multi-host mode - generate for all hosts in inventory
  HOSTNAMES="$(cat ansible/inventory/inventory.yaml | yq --raw-output '.all.hosts | keys[]')"
fi

for host in ${HOSTNAMES}
do
  # Generate BUILD_VERSION with hostname prefix
  BUILD_VERSION="${host}-${BUILD_DATE}.${BUILD_NUMBER}"
  
  sed -e "s|TEMPLATE_VERSION|${BUILD_VERSION}|" \
      -e "s|TEMPLATE_REVISION|${GIT_SHA}|" \
      -e "s|TEMPLATE_CREATED|$(date -Iseconds)|" \
      -e "s|TEMPLATE_BASE_IMAGE_REF|${BASE_IMAGE_REF}|" \
      -e "s|TEMPLATE_HOSTNAME|${host}|" \
      Containerfile.template > "Containerfile.${host}"

  echo "Generated Containerfile with:"
  echo "  VERSION: ${BUILD_VERSION}"
  echo "  REVISION: ${GIT_SHA}"
  echo "  BASE_IMAGE_REF: ${BASE_IMAGE_REF}"
done
