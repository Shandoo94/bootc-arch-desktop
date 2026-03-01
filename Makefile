OCITOOL ?= podman
BASE_IMAGE_REF ?= $(shell head -n1 base-image.lock | tr -d '[:space:]')
BUILD_VERSION ?= dev
GIT_SHA ?= $(shell git rev-parse HEAD 2>/dev/null || echo "unknown")

.PHONY: help
help:
	@echo "Arch Bootc Desktop - Build Targets"
	@echo ""
	@echo "Container Image:"
	@echo "  make containerfile   Generate Containerfile from template"
	@echo "  make build           Generate Containerfile and build image"
	@echo "  make inspect         Inspect built image"
	@echo "  make clean           Remove generated Containerfile"
	@echo ""
	@echo "Disk Image Creation:"
	@echo "  make diskimage       Create bootable disk image (requires OUTPUT=path)"
	@echo ""
	@echo "Environment variables:"
	@echo "  OCITOOL=$(OCITOOL)"
	@echo "  BASE_IMAGE_REF=$(BASE_IMAGE_REF)"
	@echo "  BUILD_VERSION=$(BUILD_VERSION)"
	@echo "  OUTPUT=<path>        Output path for disk image"
	@echo "  BOOTC_IMAGE=<ref>    Bootc image to install (default: ghcr.io/shandoo94/bootc-arch-desktop:latest)"

.PHONY: containerfile
containerfile:
	@echo "==> Generating Containerfile from template"
	BASE_IMAGE_REF="$(BASE_IMAGE_REF)" \
	BUILD_VERSION="$(BUILD_VERSION)" \
	GIT_SHA="$(GIT_SHA)" \
	./scripts/make-containerfile.sh

.PHONY: build
build: containerfile
	@echo "==> Building bootc-arch-base:$(BUILD_VERSION)"
	$(OCITOOL) build \
		-t bootc-arch-base:$(BUILD_VERSION) \
		-t bootc-arch-base:latest \
		.

.PHONY: inspect
inspect:
	@echo "==> Inspecting bootc-arch-base:$(BUILD_VERSION)"
	$(OCITOOL) images bootc-arch-base
	@echo ""
	$(OCITOOL) inspect bootc-arch-base:$(BUILD_VERSION) | jq '.[0] | {Size: .Size, Labels: .Labels}'

.PHONY: clean
clean:
	@echo "==> Cleaning generated files"
	rm -f Containerfile

.PHONY: diskimage
diskimage:
	@if [ -z "$(OUTPUT)" ]; then \
		echo "Error: OUTPUT not set"; \
		echo "Usage: make diskimage OUTPUT=path/to/image.raw"; \
		echo ""; \
		echo "Optional: Set BOOTC_IMAGE to use a specific bootc image"; \
		echo "Example: make diskimage OUTPUT=output/disk.raw BOOTC_IMAGE=localhost/bootc-arch-base:latest"; \
		exit 1; \
	fi
	@echo "==> Creating disk image: $(OUTPUT)"
	@mkdir -p "$(dir $(OUTPUT))"
	./scripts/make-diskimage.sh "$(OUTPUT)"
