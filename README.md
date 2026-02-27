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

- **distrobox** installed on your system
- Sufficient disk space (~10GB minimum for disk image + build artifacts)
- Running on a system with loop device support

### Quick Start

#### 1. Setup Builder Environment (One-Time)

```bash
make setup-builder
```

This creates an Arch Linux container with all required tools (parted, btrfs-progs, podman, etc.).

#### 2. Create Disk Image

```bash
make diskimage OUTPUT=output/mydisk.raw
```

Or with a custom bootc image:

```bash
make diskimage OUTPUT=output/mydisk.raw BOOTC_IMAGE=localhost/bootc-arch-base:latest
```

#### 3. Use the Disk Image

The resulting `.raw` file can be:
- Written to a USB drive: `dd if=output/mydisk.raw of=/dev/sdX bs=4M status=progress`
- Used with a VM (QEMU, virt-manager, etc.)
- Converted to other formats (qcow2, vmdk, etc.)

### Manual Workflow

If you prefer to work directly in the container:

```bash
# Enter the builder container
distrobox enter bootc-arch-desktop-builder

# Run the disk creation script
./scripts/make-diskimage.sh /path/to/output.raw

# Exit container
exit
```

### Configuration

- **Distrobox Config**: Edit `distrobox.ini` to modify container configuration (packages, volumes, etc.)
- **Bootc Image**: Set `BOOTC_IMAGE` environment variable:
  ```bash
  export BOOTC_IMAGE=ghcr.io/shandoo94/bootc-arch-desktop:latest
  make diskimage OUTPUT=disk.raw
  ```
- **Disk Size**: Edit `scripts/make-diskimage.sh` line 30 to change size (default: 8G)

### Cleanup

Remove the builder environment when no longer needed:

```bash
make clean-builder
```

### Why Distrobox?

The disk image creation process requires low-level tools (parted, btrfs, losetup) and a Filesystem Hierarchy Standard (FHS) compliant environment. Distrobox provides:

- **Isolation**: Dependencies don't pollute your host system
- **Reproducibility**: Same environment across different host systems (NixOS, Arch, Fedora, etc.)
- **FHS Compliance**: Required for bootc's re-exec behavior to work correctly

This approach works seamlessly on non-FHS systems like NixOS where native execution would fail.

---

## Containerfile

### Immutable State

- systemd files are placed under `/usr/lib/systemd/{system,user}/*`
- tmpfiles.d configs are placed under `/usr/lib/tmpfiles.d/*.conf`
- sysusersd configs are placed under `/usr/lib/sysusers.d/*.conf`
- Scripts/binaries are placed under `/usr/local/bin/*`
