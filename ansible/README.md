# Ansible Configuration

This directory contains Ansible roles that configure the bootc image **at build time**. The configuration is strictly limited to **root-level system configuration** that becomes part of the immutable OS image.

## Design Philosophy

### What Ansible Does (System-Level Configuration)

The Ansible setup manages **immutable, root-level system state** that can only be configured at build time:

- **Package installation** - Installing system packages via pacman
- **System services** - Enabling/configuring systemd services
- **System-wide configuration** - Files under `/etc`, `/usr`, `/var` that require root privileges
- **User account creation** - Creating system users via systemd-sysusers
- **Secrets management** - Decrypting build-time encrypted secrets at boot
- **Hardware enablement** - Configuring audio, bluetooth, removable media support

### What Ansible Does NOT Do (User-Level Configuration)

**User-level configurations are explicitly excluded** from the Ansible setup and should be managed separately:

- Dotfiles (shell configs, editor settings, terminal configs)
- Application preferences (browser settings, GUI application configs)
- Desktop environment theming (colors, wallpapers, fonts, icon themes)
- User-specific scripts and utilities
- Personal keybindings and shortcuts

**Rationale**: Including user-level configuration in the bootc image would require a complete container rebuild and download for trivial changes (e.g., changing a display option in yazi). User-level configuration should be managed in the mutable filesystem using day-1 configuration tools.

## Role Overview

| Role | Purpose | Configuration Scope |
|------|---------|-------------------|
| `base_config` | Basic machine settings (sudo, hostname, locale, timezone) | System-wide settings in `/etc` |
| `secrets` | SOPS-encrypted secrets decryption at boot | Secrets management infrastructure |
| `user_creation` | System user creation via systemd-sysusers | User accounts and home directories |
| `desktop_hardware` | Hardware support (audio, bluetooth, removable media) | Hardware service enablement |
| `desktop_hyprland` | Hyprland desktop packages and login manager | Package installation + greetd config |

## Usage

### Modifying Configuration

1. **Edit role variables** in `inventory/group_vars/all.yaml` or role defaults
2. **Rebuild the container image** to apply changes
3. **Deploy the new image** using bootc

### Adding New Roles

Follow the project conventions in `AGENTS.md`:
- Place roles in `ansible/roles/<role_name>/`
- Include a `README.md` documenting purpose and variables
- Use Linux FHS best practices for file placement
- Ensure idempotency - roles must be safely re-runnable

## Directory Structure

```
ansible/
├── inventory/              # Ansible inventory and variables
│   ├── group_vars/
│   │   └── all.yaml       # Global variables
│   └── inventory.yaml     # Inventory definition
├── roles/                 # Ansible roles
│   ├── base_config/       # Basic system configuration
│   ├── secrets/           # Secrets management
│   ├── user_creation/     # User account creation
│   ├── desktop_hardware/  # Hardware support
│   └── desktop_hyprland/  # Desktop environment
├── secrets/               # SOPS-encrypted secrets
│   ├── .sops.yaml        # SOPS configuration
│   ├── global_secrets.yaml
│   └── host_secrets.yaml
└── site.yaml             # Main playbook
```

## File Placement Conventions

Following Linux FHS and systemd best practices:

- **Custom configs**: `/usr/local/share/config/<role-name>/`
- **Scripts/binaries**: `/usr/local/bin/`
- **Systemd units**: `/usr/lib/systemd/system/`
- **Systemd drop-ins**: `/usr/lib/systemd/system/<service>.d/`
- **tmpfiles.d**: `/usr/lib/tmpfiles.d/`
- **sysusers.d**: `/usr/lib/sysusers.d/`

## See Also

- Individual role READMEs in `roles/*/README.md` for detailed documentation
- `AGENTS.md` for project conventions and guidelines
- `Containerfile` for build process integration
