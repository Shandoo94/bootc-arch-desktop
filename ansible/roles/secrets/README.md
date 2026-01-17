# Secrets Role

## Overview

This Ansible role implements sops-nix-like secrets management for immutable bootc images. Secrets are encrypted with SOPS at build time, shipped in the container image, and decrypted at boot time to tmpfs (`/run/secrets`).

## Prerequisites

For host-specific secrets to work correctly in containerized builds, the playbook must set the `container_hostname` fact from `/etc/hostname` before running this role. This is because Ansible's automatic fact gathering may not detect the hostname correctly in container environments.

**Example in your playbook:**
```yaml
- name: Configure system
  hosts: localhost
  connection: local
  tasks:
    - name: Read hostname from /etc/hostname
      ansible.builtin.slurp:
        src: /etc/hostname
      register: hostname_content
      tags: [always]

    - name: Set container_hostname fact from /etc/hostname
      ansible.builtin.set_fact:
        container_hostname: "{{ hostname_content.content | b64decode | trim }}"
      tags: [always]
  roles:
    - secrets
```

## Architecture

### Build Time (Ansible)
1. Install `sops` and `yq` packages
2. Copy encrypted secret files to `/usr/share/secrets/`
3. Install decryption script to `/usr/local/bin/decrypt-secrets`
4. Install and enable systemd service `sops-secrets.service`

### Installation Time (Manual)
User must place the age private key at `/var/lib/sops/age/key.txt` before first boot.

### Boot Time (Systemd)
1. `sops-secrets.service` runs early in boot (before `systemd-sysusers.service`)
2. Decryption script reads age key from `/var/lib/sops/age/key.txt`
3. Decrypts global secrets → `/run/secrets/share/{hierarchy}`
4. Decrypts host-specific secrets → `/run/secrets/host/{hierarchy}`
5. All secrets are stored in tmpfs with restrictive permissions

## Secret Types

### Global Secrets
- **Source**: `ansible/secrets/global_secrets.yaml`
- **Destination**: `/run/secrets/share/`
- **Structure**: Flat YAML hierarchy, all keys preserved as directory structure
- **Example**:
  ```yaml
  user_pw:
    tiwaz: <encrypted-password>
  ```
  Becomes: `/run/secrets/share/user_pw/tiwaz`

### Host-Specific Secrets
- **Source**: `ansible/secrets/host_secrets.yaml`
- **Destination**: `/run/secrets/host/`
- **Structure**: Top-level keys are hostnames, hierarchy starts from 2nd level
- **Example**:
  ```yaml
  atlas:
    ssh_host_ed25519_key: <encrypted-key>
  ```
  Becomes: `/run/secrets/host/ssh_host_ed25519_key` (on host `atlas`)

## Directory Structure

```
/usr/share/secrets/          # Build-time location (read-only)
├── global_secrets.yaml      # Encrypted global secrets
└── host_secrets.yaml        # Encrypted host-specific secrets

/var/lib/sops/age/           # Installation-time location
└── key.txt                  # Age private key (user-provided)

/run/secrets/                # Runtime location (tmpfs, 0755)
├── share/                   # Global secrets (0755)
│   └── user_pw/
│       └── tiwaz            # Secret file (0400)
└── host/                    # Host-specific secrets (0755)
    └── ssh_host_ed25519_key # Secret file (0400)
```

## File Permissions

- **Encrypted secrets** (`/usr/share/secrets/*.yaml`): `0644` (readable by all, encrypted)
- **Age key** (`/var/lib/sops/age/key.txt`): `0400` (root read-only, unencrypted)
- **Secret directories** (`/run/secrets/*`): `0755` (traversable by all)
- **Secret files** (`/run/secrets/**/*`): `0400` (root read-only, decrypted)

## Role Variables

### Source Paths (Build Time)
- `secrets_sops_config`: Path to SOPS config (default: `{{ playbook_dir }}/secrets/.sops.yaml`)
- `secrets_global`: Path to global secrets YAML (default: `{{ playbook_dir }}/secrets/global_secrets.yaml`)
- `secrets_host`: Path to host secrets YAML (default: `{{ playbook_dir }}/secrets/host_secrets.yaml`)

### Target Paths (In Image)
- `secrets_source_dir`: Where encrypted secrets are stored (default: `/usr/share/secrets`)
- `secrets_script_path`: Decryption script location (default: `/usr/local/bin/decrypt-secrets`)

### Runtime Paths (At Boot)
- `secrets_age_key_path`: Age private key location (default: `/var/lib/sops/age/key.txt`)
- `secrets_runtime_dir`: Base runtime directory (default: `/run/secrets`)
- `secrets_runtime_global_dir`: Global secrets directory (default: `/run/secrets/share`)
- `secrets_runtime_host_dir`: Host secrets directory (default: `/run/secrets/host`)

### Packages
- `secrets_packages`: List of packages to install (default: `[sops, yq]`)

### Symlink Paths (Optional)
- `secrets_paths`: Dictionary mapping secret keys to filesystem paths for symlink creation
  - `global`: Map of global secret keys to symlink destinations
  - `<hostname>`: Map of host-specific secret keys to symlink destinations (per host)

## Symlink Paths Feature

Similar to sops-nix, you can create symlinks at arbitrary filesystem locations pointing to decrypted secrets. This is useful for legacy applications expecting secrets at specific paths or system services requiring secrets in standard locations.

### Configuration Example

```yaml
secrets_paths:
  global:
    my.secret: /var/lib/app/secret
    user_pw.alice: /etc/user/password
  atlas:  # hostname (as detected by container_hostname fact)
    ssh_host_ed25519_key: /etc/ssh/ssh_host_ed25519_key
```

**Important Notes:**
- The hostname key must match the actual system hostname (from `container_hostname` fact), not the Ansible inventory hostname
- In container builds, ensure your playbook sets `container_hostname` from `/etc/hostname` (see Prerequisites section)
- Example: If you set the hostname with `echo "atlas" > /etc/hostname` in your Containerfile, use `atlas` as the key in `secrets_paths`

### How It Works

1. **Build Time Validation**: Ansible validates that all referenced secret keys exist in the encrypted YAML files (keys are visible even when encrypted)
2. **tmpfiles.d Generation**: Ansible generates `/usr/lib/tmpfiles.d/sops-secrets-symlinks.conf` with symlink directives
3. **Boot Time Creation**: After secrets are decrypted, systemd-tmpfiles creates the symlinks automatically

### Results

Using the configuration above on host `atlas`:
- `/var/lib/app/secret` → `/run/secrets/share/my/secret`
- `/etc/user/password` → `/run/secrets/share/user_pw/alice`
- `/etc/ssh/ssh_host_ed25519_key` → `/run/secrets/host/ssh_host_ed25519_key`

Parent directories are automatically created with `0755` permissions.

### Validation

If you reference a non-existent secret key, the Ansible build will fail with a clear error message:

```
FAILED! => {"assertion": "...", "msg": "Secret 'nonexistent.key' referenced in paths.global does not exist in /path/to/global_secrets.yaml"}
```

This prevents deployment of broken configurations.

### Use Cases

- **SSH Host Keys**: Place decrypted SSH host keys at `/etc/ssh/ssh_host_*_key`
- **Application Secrets**: Legacy apps expecting secrets at hardcoded paths like `/etc/app/secret`
- **Service Credentials**: System services requiring credentials in specific locations
- **Compatibility**: Migrate existing applications without code changes

## Usage

### Adding New Secrets

1. Edit the appropriate YAML file:
   ```bash
   # For global secrets
   sops ansible/secrets/global_secrets.yaml
   
   # For host-specific secrets
   sops ansible/secrets/host_secrets.yaml
   ```

2. Add secrets following the hierarchy convention:
   ```yaml
   # Global secrets - flat hierarchy
   service:
     api_key: "secret-value"
   
   # Host secrets - keyed by hostname
   atlas:
     service:
       config: "host-specific-value"
   ```

3. Rebuild the container image with the updated secrets

### Accessing Secrets at Runtime

Secrets are available as files in `/run/secrets/`:

```bash
# Read a global secret
cat /run/secrets/share/service/api_key

# Read a host-specific secret
cat /run/secrets/host/service/config
```

### Installing the Age Key

Before first boot of the system, place your age private key:

```bash
# On the installed system
mkdir -p /var/lib/sops/age
install -m 0400 /path/to/age.key /var/lib/sops/age/key.txt
```

The age key must match one of the recipients in `.sops.yaml`.

## Security Model

### Defense in Depth
1. **Encrypted at rest**: Secrets are SOPS-encrypted in the container image
2. **Key separation**: Age private key is NOT in the container image
3. **Runtime decryption**: Secrets only exist decrypted in tmpfs (RAM)
4. **Restrictive permissions**: Secret files are `0400` (root read-only)
5. **Boot-time only**: Decryption happens once at boot, not continuously

### Threat Model
- **Container image compromise**: Encrypted secrets are useless without age key
- **Running system compromise**: If attacker has root, they can read `/run/secrets/`
- **Age key compromise**: Attacker can decrypt secrets from any container image

### Best Practices
1. Protect the age private key with filesystem permissions (`0400`)
2. Use different age keys for different environments (prod/staging/dev)
3. Rotate secrets periodically by updating YAML files and rebuilding images
4. Store age keys in secure location (hardware token, encrypted volume, etc.)
5. Use host-specific secrets for sensitive per-machine configuration

## Troubleshooting

### System boots but secrets are missing

Check if the service ran:
```bash
systemctl status sops-secrets.service
journalctl -u sops-secrets.service
```

### Decryption fails

Verify age key exists and is readable:
```bash
ls -la /var/lib/sops/age/key.txt
# Should be: -r-------- 1 root root
```

Test manual decryption:
```bash
export SOPS_AGE_KEY_FILE=/var/lib/sops/age/key.txt
sops -d /usr/share/secrets/global_secrets.yaml
```

### Wrong hostname

The script uses `hostname` command. Verify:
```bash
hostname
# Check if this matches a key in host_secrets.yaml
```

### Service fails to start

Check systemd journal:
```bash
journalctl -xeu sops-secrets.service
```

Common issues:
- Age key missing: Place key at `/var/lib/sops/age/key.txt`
- Wrong age key: Ensure key matches SOPS recipients
- Corrupted secrets file: Re-encrypt with correct key

## Systemd Service Details

**Unit Name**: `sops-secrets.service`

**Ordering**:
- Runs after: `local-fs.target` (requires mounted filesystems)
- Runs before: `systemd-sysusers.service` (user passwords may be in secrets)
- Runs before: `sysinit.target` (early boot)

**Failure Behavior**:
- If age key is missing: Service fails, system continues booting
- If decryption fails: Service fails, system continues booting
- Errors are logged to systemd journal

**Note**: The system remains functional even if secrets fail to decrypt. This allows recovery through alternate means (console access, emergency mode, etc.).

## Integration with Other Roles

This role is designed to run early in the playbook before roles that may need secrets (e.g., user creation with passwords).

Example playbook order:
```yaml
roles:
  - secrets        # Install secrets management
  - user_creation  # May read passwords from /run/secrets/share/
  - theme
```

## Tags

- `secrets`: All tasks in this role
- `packages`: Package installation tasks only
- `systemd`: Systemd service tasks only

## Dependencies

None. This role has no Ansible role dependencies.

## License

Same as parent project.
