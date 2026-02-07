# base_config

Configures basic machine-level settings including sudo access and hostname persistence.

## Overview

This role provides basic and essential system configuration:

- **Sudo installation**: Installs the sudo package for privilege escalation
- **Wheel group sudoers**: Configures the wheel group to have full sudo access via `/etc/sudoers.d/wheel`
- **Timezone**: Sets the system timezone via tmpfiles.d symlink in `/etc/localtime`
- **Locale**: Configures system locales by uncommenting entries in `/etc/locale.gen`, generating them with `locale-gen`, and setting `LANG` in `/usr/local/share/config/locale.conf` symlinked to `/etc/locale.conf`
- **Hostname**: The hostname is taken from a kernel argument which is set at installation time. This is to avoid container build for every host, which would only differ by the entry in `/etc/hostname`.

## Dependencies

No external role dependencies required.
