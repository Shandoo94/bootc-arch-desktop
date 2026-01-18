# base_config

Configures basic machine-level settings including sudo access and hostname persistence.

## Overview

This role provides essential system configuration that must be applied early in the boot process:

- **Sudo installation**: Installs the sudo package for privilege escalation
- **Wheel group sudoers**: Configures the wheel group to have full sudo access via `/etc/sudoers.d/wheel`
- **Timezone**: Sets the system timezone via tmpfiles.d symlink in `/etc/localtime`
- **Locale**: Configures system locales by uncommenting entries in `/etc/locale.gen`, generating them with `locale-gen`, and setting `LANG` in `/usr/local/share/config/locale.conf` symlinked to `/etc/locale.conf`
- **Hostname**: Sets the hostname in `/usr/local/share/config/hostname` symlinked to `/etc/hostname` via tmpfiles.d, ensuring DHCP can register the correct hostname for DNS

## Dependencies

No external role dependencies required.

## Variables

This role uses the following variables:

- `inventory_hostname`: The hostname to set (taken from Ansible inventory)
- `base_config_locales`: List of locales to enable (default: `['en_US.UTF-8']`)
- `base_config_timezone`: Timezone to set (default: `UTC`)

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
- `localization`: Locale and timezone tasks
- `hostname`: Hostname configuration tasks
- `systemd`: Systemd service tasks

## Files Created

- `/etc/sudoers.d/wheel` - Wheel group sudoers configuration
- `/etc/localtime` - Timezone symlink
- `/usr/lib/tmpfiles.d/timezone.conf` - Tmpfiles.d timezone configuration
- `/usr/lib/tmpfiles.d/locale.conf` - Tmpfiles.d locale symlink configuration
- `/usr/lib/tmpfiles.d/hostname.conf` - Tmpfiles.d hostname symlink configuration
- `/usr/local/share/config/locale.conf` - Locale configuration with LANG setting
- `/usr/local/share/config/hostname` - Hostname configuration
