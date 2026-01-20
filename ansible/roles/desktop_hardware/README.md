# desktop_hardware

Configures desktop hardware services including audio, bluetooth, and removable media support.

## Overview

This role sets up essential desktop hardware components:

- **Audio**: Installs PipeWire for modern audio/m JACK support
- **Bluetooth**: Installs Bluez with blueman tray applet and enables the bluetooth service
- **Removable Media**: Installs udisks2 for mounting external drives

## Dependencies

No external role dependencies required.

## Variables

This role uses the following variables (all have defaults):

| Variable | Description | Default |
|----------|-------------|---------|
| `desktop_hardware_pipewire_packages` | PipeWire packages to install | `['pipewire', 'pipewire-jack', 'pipewire-pulse', 'pipewire-alsa', 'wireplumber']` |
| `desktop_hardware_bluetooth_packages` | Bluetooth packages to install | `['bluez', 'bluez-utils', 'blueman']` |
| `desktop_hardware_storage_packages` | Storage packages to install | `['udisks2']` |

## Tags

- `desktop_hardware` - Main tag for all desktop_hardware tasks
- `desktop_hardware:packages` - Package installation tasks
- `desktop_hardware:bluetooth` - Bluetooth configuration tasks

## Services Enabled

- `bluetooth.service` - Bluetooth daemon
