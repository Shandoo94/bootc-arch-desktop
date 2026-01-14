# AGENTS.md

## Project Overview

This project customizes a bootc base image to create immutable OS images for further use. The image state is managed by Ansible roles which install software and write configurations. Changes to the image are made through Ansible roles, not by modifying the running system directly.

## Ansible Guidelines

Adhere to the general best practices for Ansible.

### Role Structure
- Place roles in `ansible/rules/<role_name>/`
- Include a `README.md` in each role documenting its purpose and variables
- If applicable, the default variables for a role should be ordered in a struct `{{role_name}}_config`

### Task Design
- Use Ansible modules instead of shell commands when possible
- Include `changed_when: false` for idempotent commands that always report changed
- Use `check_mode: yes` where appropriate for dry-run validation
- Group related tasks with `block` and handle errors with `rescue`
- Always specify `become: yes` explicitly for privileged operations

### Idempotency
- Ensure all tasks can be run multiple times without side effects
- Use `creates` or `removes` parameters for command modules
- Test playbooks with `ansible-playbook --check` before committing

### Security
- Never hardcode secrets; use Ansible Vault or environment variables
- Set file permissions explicitly with `mode` parameter
- Use `no_log: yes` for tasks handling sensitive data

## Containerfile Guidelines

Use the general best practices for writing Containerfiles.

### Layer Ordering
- Order instructions from least to most frequently changing
- Install dependencies before copying application code
- Place configuration changes last to maximize cache reuse

### Package Management
- Clean up package cache after installations (`pacman -Scc`)
- Combine related RUN instructions to reduce layers
- Avoid installing unnecessary packages

### Security Best Practices
- Don't include secrets in the image
- Use `--no-install-recommends` to minimize attack surface
- Set appropriate file permissions in COPY/ADD commands
- Add healthchecks with `HEALTHCHECK` instruction

### Labels
- Add maintainer contact information
- Use OCI image spec annotations for metadata

## Project Conventions

### Naming Conventions
- Ansible roles: lowercase with underscores (`theme`, `user_management`)
- Variables: lowercase with underscores (`theme_name`, `user_groups`)
- Files: lowercase with hyphens where appropriate
- Tags: descriptive, role-based (`theme`, `systemd`)

### Git Workflow
- Use feature branches for changes
- Commit messages: imperative mood, concise summary
- Pull requests for review before merging to main

## Validation

### Pre-commit Checks
```bash
# Ansible lint
ansible-lint ansible/site.yaml

# Containerfile lint
hadolint Containerfile

# Ansible dry-run
./scripts/make-containerfile.sh # Create Containerfile
podman build -t bootc-arch-desktop:dev .
```

### Bootc Validation
The final image must pass `bootc container lint` before deployment.

## Troubleshooting

- Image build fails: Check Containerfile layer order and base image availability
- Ansible idempotency issues: Verify `creates`/`removes` flags on command tasks
- Bootc lint failures: Ensure image meets OCI spec and has required labels
- Be conservative when reading logs. Use `head` to truncate.
