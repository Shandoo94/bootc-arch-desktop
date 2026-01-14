# Arch Bootc Desktop

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

## Containerfile

### Immutable State

- systemd files are placed under `/usr/lib/systemd/{system,user}/*`
- tmpfiles.d configs are placed under `/usr/lib/tmpfiles.d/*.conf`
- sysusersd configs are placed under `/usr/lib/sysusers.d/*.conf`
- Scripts/binaries are placed under `/usr/local/bin/*`
