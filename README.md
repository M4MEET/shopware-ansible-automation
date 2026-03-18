# Shopware Ansible Automation

Ansible playbooks to automate the installation and configuration of a complete Shopware 6 platform environment on Ubuntu servers. Handles Nginx, PHP, MariaDB, firewall, SSL, and Shopware deployment.

## Requirements

- Ansible 2.9+
- Target server running Ubuntu (Debian-based)
- SSH access to the target server

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/shopware-ansible-automation.git
cd shopware-ansible-automation/try-ansible
```

### 2. Install Ansible Galaxy collections

```bash
ansible-galaxy collection install -r requirements.yml
```

### 3. Create your inventory

```bash
cp inventory.sample inventory
```

Edit `inventory` with your server IP or hostname:

```ini
[remote_servers]
your_server_ip_or_domain ansible_user=root
```

### 4. Set up Ansible Vault for secrets

Create a vault password file (this is gitignored):

```bash
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass
```

Edit the vault file with your real database password:

```bash
ansible-vault encrypt group_vars/remote_servers/vault.yml
ansible-vault edit group_vars/remote_servers/vault.yml
```

### 5. Run the playbook

```bash
# With vault password file
ansible-playbook playbook.yml -i inventory -v --vault-password-file .vault_pass

# Or prompt for vault password interactively
ansible-playbook playbook.yml -i inventory -v --ask-vault-pass
```

### 6. Access Shopware

Once the playbook completes, Shopware is available at your server's IP or domain on port 80 (or 443 if SSL is enabled).

## Roles

| Role | Description |
|------|-------------|
| **common** | Updates apt cache, installs base utilities, configures swap |
| **ufw** | Configures UFW firewall (allows SSH, HTTP, HTTPS only) |
| **php** | Adds ondrej/php PPA, installs PHP + FPM + extensions, deploys pool tuning |
| **database** | Installs MariaDB or MySQL (configurable via `db_engine`), hardens it, creates Shopware DB and user |
| **nginx** | Installs Nginx, deploys Shopware vhost config, configures log rotation, optional SSL via Let's Encrypt |
| **shopware** | Installs Composer (with hash verification), installs Shopware, generates `.env`, runs `system:install`, warms cache |

## Tags

Run specific parts of the playbook:

```bash
# Only run nginx and php roles
ansible-playbook playbook.yml --tags "nginx,php"

# Skip firewall setup
ansible-playbook playbook.yml --skip-tags "firewall"

# Only run security-related tasks
ansible-playbook playbook.yml --tags "security"
```

Available tags: `common`, `setup`, `ufw`, `security`, `firewall`, `php`, `mariadb`, `database`, `nginx`, `webserver`, `shopware`, `app`.

## Configuration

All values are configurable through role defaults in `roles/<role>/defaults/main.yml`. Override them via `group_vars/`, `host_vars/`, or the `-e` flag.

### Core variables

| Variable | Default | Role |
|----------|---------|------|
| `db_engine` | `mariadb` | database |
| `php_version` | `8.2` | php, nginx |
| `mariadb_version` | `10.11` | database |
| `mysql_version` | `8.0` | database |
| `shopware_version` | `6.5.8.7` | shopware |
| `shopware_root` | `/var/www/shopware` | shopware, nginx |
| `server_name` | `_` | nginx |
| `shopware_db_name` | `shopware` | database |
| `shopware_db_user` | `shopware` | database |
| `shopware_db_password` | *(vault)* | vault |
| `shopware_app_url` | `http://localhost` | shopware |

### SSL/TLS (Let's Encrypt)

| Variable | Default | Description |
|----------|---------|-------------|
| `ssl_enabled` | `false` | Enable certbot SSL |
| `certbot_email` | `""` | Email for Let's Encrypt |
| `certbot_auto_renew` | `true` | Auto-renew via cron |

### PHP-FPM pool tuning

| Variable | Default |
|----------|---------|
| `php_fpm_pm` | `dynamic` |
| `php_fpm_max_children` | `50` |
| `php_fpm_start_servers` | `5` |
| `php_fpm_memory_limit` | `512M` |
| `php_fpm_upload_max_filesize` | `128M` |
| `php_fpm_max_execution_time` | `300` |

### Firewall

| Variable | Default |
|----------|---------|
| `ufw_default_policy` | `deny` |
| `ufw_allowed_ports` | SSH (22), HTTP (80), HTTPS (443) |

### Swap

| Variable | Default |
|----------|---------|
| `swap_enabled` | `true` |
| `swap_size_mb` | `2048` |

**Example:** deploy with MySQL instead of MariaDB, a different PHP version, and SSL:

```bash
ansible-playbook playbook.yml \
  -e "db_engine=mysql php_version=8.3 ssl_enabled=true certbot_email=admin@example.com server_name=shop.example.com"
```

## Local Testing with Docker

```bash
docker-compose up ansible
```

This builds the Ansible container, installs Galaxy collections, and runs a syntax check. A target Ubuntu container is also started for integration testing.

## Project Structure

```
try-ansible/
├── ansible.cfg
├── inventory.sample
├── playbook.yml
├── requirements.yml
├── .ansible-lint
├── group_vars/
│   └── remote_servers/
│       ├── vars.yml              # Variable indirection (references vault)
│       └── vault.yml             # Encrypted secrets (gitignored)
└── roles/
    ├── common/
    │   ├── defaults/main.yml
    │   └── tasks/main.yml
    ├── ufw/
    │   ├── defaults/main.yml
    │   └── tasks/main.yml
    ├── php/
    │   ├── defaults/main.yml
    │   ├── handlers/main.yml
    │   ├── tasks/main.yml
    │   └── templates/www.conf.j2
    ├── database/
    │   ├── defaults/main.yml
    │   ├── handlers/main.yml
    │   └── tasks/
    │       ├── main.yml          # Dispatches to mariadb.yml or mysql.yml
    │       ├── mariadb.yml
    │       └── mysql.yml
    ├── nginx/
    │   ├── defaults/main.yml
    │   ├── handlers/main.yml
    │   ├── meta/main.yml
    │   ├── tasks/main.yml
    │   └── templates/
    │       ├── shopware-nginx.conf.j2
    │       ├── logrotate-nginx.j2
    │       └── logrotate-shopware.j2
    └── shopware/
        ├── defaults/main.yml
        ├── meta/main.yml
        ├── tasks/main.yml
        └── templates/shopware.env.j2
```

## Security Notes

- **Do not commit** the `inventory` file — it contains real server IPs (it is gitignored; use `inventory.sample` as a starting point).
- **Database password** is stored in Ansible Vault (`group_vars/remote_servers/vault.yml`). Encrypt it before committing.
- **Composer installer** is hash-verified against the official signature before execution.
- **Database** (MariaDB or MySQL) is hardened automatically: anonymous users removed, test DB dropped, remote root disabled.
- **UFW firewall** denies all incoming traffic except SSH, HTTP, and HTTPS.
- The playbook connects as `root` via SSH. For production, consider using a non-root user with `become` privilege escalation.
