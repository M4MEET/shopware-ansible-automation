# Shopware Ansible Automation

This repository contains Ansible playbooks to automate the installation and configuration of a complete Shopware platform environment. The playbooks handle the setup of services like Nginx, MariaDB, PHP, and install Shopware using Composer.

## Features

- **Shopware Installation**: Automated installation of Shopware via Composer (version 6.5.8.7 or latest).
- **Nginx, PHP, MariaDB Configuration**: Automates the setup and configuration of required services for optimal Shopware performance.
- **Service Management**: Handles starting, enabling, and restarting services like Nginx and MariaDB, even in non-systemd environments.
- **Permissions Management**: Ensures proper ownership and permissions for Shopware directories and files.

## Requirements

- Ansible 2.9 or higher
- A target server running a Debian-based distribution (e.g., Ubuntu)
- SSH access to the target server
- Git installed on the local machine and target server
- Composer installed (or will be installed via the playbook)

## Playbook Structure

- **roles/**:
  - **nginx**: Configures Nginx for serving Shopware.
  - **php**: Installs PHP 8.2 and required extensions for Shopware.
  - **mariadb**: Installs and configures MariaDB for Shopware.
  - **shopware**: Handles Shopware installation via Composer.
  - **common**: Common tasks like updating packages, installing utilities, and creating directories.

## Installation

### Step 1: Clone the Repository
```bash
git clone https://github.com/yourusername/shopware-ansible-automation.git
cd shopware-ansible-automation
Step 2: Update Inventory File
Modify the inventory file to match your server's configuration:

ini
Copy code
[shopware]
your_server_ip_or_domain
Step 3: Run the Playbook
Run the playbook with the following command:

bash
Copy code
ansible-playbook playbook.yml -i inventory -v
Step 4: Access Shopware
Once the playbook completes, Shopware will be installed and ready to access in your web browser at your server's domain or IP address.

Playbook Details
Nginx Configuration
Nginx is installed and configured to serve Shopware. You can customize the configuration template located at:

bash
Copy code
roles/nginx/templates/shopware-nginx.conf.j2
PHP Installation
The playbook installs PHP 8.2 along with all required extensions for Shopware, such as curl, pdo_mysql, gd, mbstring, etc.

MariaDB Setup
MariaDB 10.3 is installed and configured as the database for Shopware. You can modify the database connection settings by updating the playbook in:

bash
Copy code
roles/mariadb/tasks/main.yml
Shopware Installation
Shopware is installed using Composer with the following command:

bash
Copy code
composer create-project shopware/production:6.5.8.7 /var/www/shopware --no-interaction
You can modify the version or install the latest version by removing the version specification.

Customization
Feel free to modify the playbooks according to your specific requirements:

Update configuration files
Add custom roles for additional services
Modify the playbook to use different versions of Shopware or PHP
