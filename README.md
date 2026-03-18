# Arch Bootc Desktop

A small project to build a bootc-based arch desktop installation.
Still in beta.

## Quick Start

### Build the base image

Using the Makefile (recommended):

```bash
make build
```

Or manually:

```bash
./scripts/make-containerfile.sh  # Generate Containerfile from template
podman build -t bootc-arch-desktop .
```

## Creating Bootable Disk Images

### Prerequisites

- Sufficient disk space (~10GB minimum for disk image + build artifacts)
- Running on a system with loop device support

### Installation

The image is installed to a virtual disk.
Use the following make command:

```bash
make diskimage OUTPUT=output/install-image.raw
```

This will install the latest container image from the registry onto the raw disk via a loop device.
The disk is formatted as `btrfs` with a separate subvolume for `/var`.

### Key Injection

After installation, the age key must be injected into the diskimage, so the systemd service can decrypt the hoost secrets.

```bash
make inject-key \
    OUTPUT=output/install-image.raw \
    SECRETS_FILE=ansible/secrets/host_secrets.yaml \
    SECRETS_KEY=atlas.age_key
```

Both steps can be combined:
```bash
make diskimage inject-key \
    OUTPUT=output/disk.raw \
    BOOTC_IMAGE=localhost/bootc-arch-base:latest \
    SECRETS_FILE=ansible/secrets/host_secrets.yaml \
    SECRETS_KEY=primary_key
```


---

## Containerfile

### Immutable State

- systemd files are placed under `/usr/lib/systemd/{system,user}/*`
- tmpfiles.d configs are placed under `/usr/lib/tmpfiles.d/*.conf`
- sysusersd configs are placed under `/usr/lib/sysusers.d/*.conf`
- Scripts/binaries are placed under `/usr/local/bin/*`
