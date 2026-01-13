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
