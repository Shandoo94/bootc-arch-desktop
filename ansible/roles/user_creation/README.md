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
- `systemd-sysusers.service` runs after `sops-secrets.service` at boot

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
| `/etc/systemd/system/systemd-sysusers.service.d/bootc-credentials.conf` | Credential loading |

## Boot Order

1. `sops-secrets.service` - Decrypts secrets to `/run/secrets/`
2. `systemd-sysusers.service` - Creates users with credentials from decrypted secrets
3. `systemd-tmpfiles.service` - Creates home directories

## Idempotency

The role is idempotent and can be run multiple times safely. It will skip users/groups that already exist.
