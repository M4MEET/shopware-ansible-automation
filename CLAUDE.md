# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ansible playbooks for automating deployment of a Shopware 6 e-commerce platform on Ubuntu servers. Deploys UFW firewall, Nginx (with optional SSL), PHP, MariaDB, and Shopware with all required dependencies.

## Key Commands

```bash
cd try-ansible

# Install required Ansible Galaxy collections
ansible-galaxy collection install -r requirements.yml

# Run the full playbook (with vault)
ansible-playbook playbook.yml -i inventory -v --vault-password-file .vault_pass

# Syntax check
ansible-playbook playbook.yml --syntax-check

# Dry run (check mode)
ansible-playbook playbook.yml --check

# Run specific roles via tags
ansible-playbook playbook.yml --tags "nginx,php"

# Skip a role
ansible-playbook playbook.yml --skip-tags "firewall"

# Vault operations
ansible-vault encrypt group_vars/remote_servers/vault.yml
ansible-vault edit group_vars/remote_servers/vault.yml
ansible-vault decrypt group_vars/remote_servers/vault.yml

# Local testing with Docker
docker-compose up ansible
```

## Architecture

The Ansible project lives in `try-ansible/`. The Dockerfile at the repo root provides an Ubuntu 24.04 container with Ansible pre-installed. `docker-compose.yml` provides both an Ansible controller and a target Ubuntu container.

**Playbook execution order** (defined in `try-ansible/playbook.yml`):
1. **common** — apt cache update, install base utilities, configure swap
2. **ufw** — configure UFW firewall (deny all, allow SSH/HTTP/HTTPS)
3. **php** — adds `ppa:ondrej/php`, installs PHP + FPM + extensions, deploys pool tuning config
4. **mariadb** — adds MariaDB repo (signed key), installs server, hardens (removes anon users, test DB, remote root), creates Shopware DB and user
5. **nginx** — installs Nginx, deploys Shopware vhost, removes default site, configures log rotation, optional SSL via certbot
6. **shopware** — installs Composer (hash-verified), installs Shopware, generates `.env`, runs `system:install --basic-setup`, warms cache

**Role dependencies** (via `meta/main.yml`): nginx depends on php; shopware depends on mariadb and nginx.

## Secrets Management

Secrets use Ansible Vault with variable indirection:
- `group_vars/remote_servers/vault.yml` — encrypted file containing `vault_shopware_db_password`
- `group_vars/remote_servers/vars.yml` — maps `shopware_db_password` to the vault variable
- Pass `--vault-password-file .vault_pass` or `--ask-vault-pass` at runtime
- Both `vault.yml` and `.vault_pass` are gitignored

## Variables

All roles use `defaults/main.yml` for configurable values. Override via `group_vars/`, `host_vars/`, or `-e`.

Key variables: `php_version`, `mariadb_version`, `shopware_version`, `shopware_root`, `server_name`, `ssl_enabled`, `certbot_email`, `swap_enabled`, `swap_size_mb`, `ufw_allowed_ports`, `php_fpm_*` pool settings.

## Tags

`common`, `setup`, `ufw`, `security`, `firewall`, `php`, `mariadb`, `database`, `nginx`, `webserver`, `shopware`, `app`.

## Conventions

- Roles follow standard Ansible layout: `defaults/`, `tasks/`, `templates/`, `handlers/`, `meta/`
- Service restarts are handler-driven (only triggered on config changes)
- Shopware runs as `www-data`; Composer runs under that user with `COMPOSER_HOME=/tmp/composer`
- Target OS is Ubuntu (Debian-based); package management uses `apt`
- MariaDB repo uses `{{ ansible_distribution_release }}` to match the target OS codename
- Idempotency: Composer install and Shopware create-project use `creates:` guards
- CI runs ansible-lint and syntax-check via GitHub Actions on push/PR to main
