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
make diskimage OUTPUT=output/disk.raw
```

This will install the latest container image from the registry onto the raw disk via a loop device.
The disk is formatted as `btrfs` with a separate subvolume for `/var`.

### Hostname Configuration

You can specify a hostname that will be embedded in the disk image via a kernel argument.
The hostname is set at boot time by a systemd service that reads `bootc.hostname` from the kernel command line.

```bash
make diskimage OUTPUT=output/disk.raw IMAGE_HOSTNAME=workstation
```

When `IMAGE_HOSTNAME` is provided:
- The output filename is suffixed with the hostname (e.g., `disk.raw` becomes `disk-workstation.raw`)
- The kernel argument `bootc.hostname=workstation` is added to the bootloader configuration
- At first boot, the hostname is written to `/etc/hostname`

### Key Injection

After installation, the age key must be injected into the diskimage, so the systemd service can decrypt the hoost secrets.

```bash
make inject-key \
    OUTPUT=output/disk.raw \
    SECRETS_FILE=ansible/secrets/host_secrets.yaml \
    SECRETS_KEY=prima
```

Both steps can be combined:
```bash
make diskimage inject-key \
    OUTPUT=output/disk.raw \
    IMAGE_HOSTNAME=atlas \
    BOOTC_IMAGE=localhost/bootc-arch-base:latest \
    SECRETS_FILE=ansible/secrets/host_secrets.yaml \
    SECRETS_KEY=primary_key
```

This creates `output/install-image-atlas.raw` with the hostname `atlas` configured.


---

## Containerfile

### Immutable State

- systemd files are placed under `/usr/lib/systemd/{system,user}/*`
- tmpfiles.d configs are placed under `/usr/lib/tmpfiles.d/*.conf`
- sysusersd configs are placed under `/usr/lib/sysusers.d/*.conf`
- Scripts/binaries are placed under `/usr/local/bin/*`
