# Desktop Environment: Hyprland

Sets up Hyprland as desktop environment.

## Components

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

## Configuration

Configuration files are installed to `{{ desktop_hypr_source_dir }}` and symlinked to each user's home directory via systemd-tmpfiles.

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `desktop_hypr_source_dir` | Source directory for configs | `/usr/local/share/config/hypr` |
| `desktop_hypr_users` | List of users for symlinks | `user_creation_data` |
| `desktop_hypr_screen_lock_timeout` | Screen lock timeout (seconds) | `180` |
| `desktop_hypr_screen_off_timeout` | Screen off timeout (seconds) | `240` |
| `desktop_hypr_suspend_timeout` | Suspend timeout (seconds) | `540` |

## Tags

- `desktop_hyprland` - General role tasks
- `desktop_hyprland:packages` - Package installation
- `desktop_hyprland:config` - Configuration file management
- `desktop_hyprland:tmpfiles` - Tmpfiles and symlink generation
