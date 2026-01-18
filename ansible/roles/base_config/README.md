# base_config

Configures basic machine-level settings including sudo access and hostname persistence.

## Overview

This role provides essential system configuration that must be applied early in the boot process:

- **Sudo installation**: Installs the sudo package for privilege escalation
- **Wheel group sudoers**: Configures the wheel group to have full sudo access via `/etc/sudoers.d/wheel`
- **Hostname persistence**: Uses a systemd service to set the hostname from `inventory_hostname` before network initialization, ensuring DHCP can register the correct hostname for DNS

## Dependencies

No external role dependencies required.

## Variables

This role uses the following variables:

- `inventory_hostname`: The hostname to set (taken from Ansible inventory)

## Usage

Add the role to your playbook:

```yaml
roles:
  - base_config
```

## Tags

- `base_config`: Main tag for all base_config tasks
- `packages`: Package installation tasks
- `sudo`: Sudo configuration tasks
- `systemd`: Systemd service tasks

## Files Created

- `/etc/sudoers.d/wheel` - Wheel group sudoers configuration
- `/usr/local/bin/set-hostname` - Hostname set script
- `/usr/lib/systemd/system/hostname.service` - Systemd service unit
