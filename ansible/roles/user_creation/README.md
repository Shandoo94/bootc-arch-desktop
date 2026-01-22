# User Creation Role

Creates system users using systemd-sysusers and systemd-tmpfiles.

## Overview

This role creates users with:
- Automatic group creation (user's primary group with same name)
- Extra group memberships
- Specified login shells
- Password hashes from SOPS-decrypted secrets
- Home directories at `/var/home/<username>`

## Dependencies

- `sops-secrets` role must run first (provides password hashes via SOPS)

## Variables

### `user_creation_home_dir`

Home directory base path (default: `"/var/home"`).

### `user_creation_users`

List of users to create. Each user is a dict with:

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `name` | Yes | string | Username |
| `shell` | Yes | string | Login shell path (e.g., `/bin/bash`) |
| `hashed_pw_file` | Yes | string | Path to decrypted password hash (from SOPS secrets) |
| `extra_groups` | Yes | list | Additional groups to add user to |

### `user_creation_script_path`

Path to scripts directory (default: `"/usr/local/bin"`).

### `user_creation_source_dir`

Path to config directory for user data (default: `"/usr/local/share/config/user-creation"`).

## Example Configuration

```yaml
user_creation_users:
  - name: alice
    shell: /bin/bash
    hashed_pw_file: "/run/secrets/share/user_pw.alice"
    extra_groups: ["wheel", "docker"]
  - name: bob
    shell: /usr/bin/zsh
    hashed_pw_file: "/run/secrets/host/myhost/user_pw.bob"
    extra_groups: ["www-data"]
```

## SOPS Secrets Structure

Password hashes should be stored in SOPS-encrypted YAML files under keys like:

```yaml
# global_secrets.yaml or host_secrets.yaml
user_pw:
  alice: "$6$rounds=656000$salt$hash..."
  bob: "$6$rounds=656000$another$hash..."
```

The decrypted files will be available at the paths specified in `hashed_pw_file`.

## Files Generated

| File | Purpose |
|------|---------|
| `/usr/lib/sysusers.d/bootc-users.conf` | User/group configuration |
| `/usr/lib/tmpfiles.d/bootc-users-home.conf` | Home directory configuration |
| `/usr/local/share/config/user-creation/user-data.yaml` | User data for password script |
| `/usr/local/bin/set-user-passwords.sh` | Password setting script |
| `/usr/lib/systemd/system/bootc-user-passwords.service` | Password setting service |

## Boot Order

1. `sops-secrets.service` - Decrypts secrets to `/run/secrets/`
2. `systemd-sysusers.service` - Creates users
3. `systemd-tmpfiles.service` - Creates home directories
4. `bootc-user-passwords.service` - Sets passwords from hashed credential files

## Idempotency

The role is idempotent and can be run multiple times safely. It will skip users/groups that already exist.
