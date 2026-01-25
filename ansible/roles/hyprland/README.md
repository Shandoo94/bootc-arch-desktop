# Desktop Environment: Hyprland

Installs Hyprland desktop environment packages and configures the system-level Greetd login manager.

## Packages Installed

| Component | Description |
|-----------|-------------|
| Hyprland | Compositor |
| Waybar | Status bar |
| yazi | File explorer |
| rofi | Application launcher |
| dunst | Notification daemon |
| hyprlock | Screen locker |
| hypridle | Idle daemon |
| kitty | Terminal emulator |
| greetd / greetd-tuigreet | Login manager |

Plus additional utilities: uwsm, xdg-desktop-portal-hyprland, hyprpolkitagent, qt5-wayland, qt6-wayland, swww, wlr-randr, ffmpeg, p7zip, jq, poppler, fd, ripgrep, fzf, zoxide, imagemagick.

## System Configuration

The role configures Greetd by:
1. Deploying `/usr/local/share/config/hypr/greetd-config.toml`
2. Creating a symlink from `/etc/greetd/config.toml` to the deployed config via systemd-tmpfiles
3. Enabling the greetd.service

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `desktop_hypr_source_dir` | Source directory for greetd config | `/usr/local/share/config/hypr` |

## Tags

- `desktop_hyprland` - General role tasks
- `desktop_hyprland:packages` - Package installation
- `desktop_hyprland:config` - Configuration file management
- `desktop_hyprland:greetd` - Greetd-specific tasks
- `desktop_hyprland:tmpfiles` - Tmpfiles and symlink generation
- `desktop_hyprland:systemd` - Systemd service management
