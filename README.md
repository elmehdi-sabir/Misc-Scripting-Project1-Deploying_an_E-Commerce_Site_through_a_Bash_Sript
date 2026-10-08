# Automated LAMP Stack Deployment with Bash

A beginner DevOps project that automates the deployment of a PHP product catalog on a local CentOS system using Bash, Apache, MariaDB, and PHP.

Built while following the **KodeKloud Beginner Scripting course**, this project explores how a shell script can turn manual server setup steps into an automated deployment. It is an early project in my DevOps portfolio.

> **Lab use only:** The current script is intended for a fresh, disposable virtual machine. It uses fixed demo credentials, changes system configuration, and is not ready for public or production deployment.

## Project Overview

The script provisions a single-server LAMP stack and deploys a sample storefront that reads products from MariaDB. The application demonstrates database-backed product rendering; it does not implement checkout, payments, or order management.

| Component | Role |
| --- | --- |
| Linux / CentOS | Host operating system |
| Apache (`httpd`) | Serves the website over HTTP |
| MariaDB | Stores the sample product catalog |
| PHP and `php-mysqlnd` | Render products retrieved from the database |
| Bash | Automates installation and configuration |
| `firewalld` | Manages firewall rules |

The browser requests the PHP page from Apache. PHP connects to the local MariaDB database and renders the product records.

## Deployment Workflow

1. Update system packages with `dnf`.
2. Install, start, and enable `firewalld` and MariaDB.
3. Open TCP port `3306` in the public firewall zone.
4. Create the `ecomdb` database and a local application user.
5. Create the `products` table and insert eight sample products.
6. Install Apache, PHP, and the MySQL driver, then open TCP port `80`.
7. Update Apache's index configuration and start and enable Apache.
8. Move the website files into `/var/www/html/`.
9. Create a `.env` file and insert a PHP environment-loading function into the deployed `index.php`.

## Repository Structure

| Path | Contents |
| --- | --- |
| [`1-Scripts/Deploy-LAMP_STACK.sh`](1-Scripts/Deploy-LAMP_STACK.sh) | Deployment script |
| [`2-Website/index.php`](2-Website/index.php) | PHP product catalog |
| [`2-Website/assets/db-load-script.sql`](2-Website/assets/db-load-script.sql) | Sample database schema and product data |
| `2-Website/css/`, `js/`, `img/`, `fonts/`, `vendors/`, `scss/` | Website styling, images, and supporting assets |

The script currently generates its own database seed SQL rather than importing the SQL file in `2-Website/assets/`.

## Prerequisites

- A fresh CentOS lab VM with Bash, `dnf`, and `systemd`.
- Root access or a user with `sudo` privileges.
- Internet access and working package repositories.
- Git installed to clone the repository.
- An unused `/var/www/html/` directory and no existing database named `ecomdb`.

**OS compatibility:** The exact tested CentOS release is not yet documented. The script assumes the required packages are available through `dnf` and that MariaDB permits local administrative access through `sudo mysql`. Verify these assumptions on your lab image. CentOS Linux 7 and 8 have reached end of life; see the [CentOS lifecycle information](https://www.centos.org/centos-linux/). Compatibility with CentOS Stream has not been verified for this repository.

## Getting Started

Take a VM snapshot first. The script performs a system-wide package update, changes Apache and firewall configuration, and moves files out of the cloned repository.

### 1. Clone the repository

```bash
git clone https://github.com/elmehdi-sabir/Misc-Scripting-Project1-Deploying_an_E-Commerce_Site_through_a_Bash_Sript.git
cd Misc-Scripting-Project1-Deploying_an_E-Commerce_Site_through_a_Bash_Sript
```

### 2. Review and run the script

Run these commands from the **repository root**. The current script uses relative paths to locate the website files.

```bash
less 1-Scripts/Deploy-LAMP_STACK.sh
bash -n 1-Scripts/Deploy-LAMP_STACK.sh
sudo bash 1-Scripts/Deploy-LAMP_STACK.sh
```

`bash -n` checks shell syntax only; it does not validate deployment behavior. The script is not currently safe to rerun. If deployment fails or you want to repeat the exercise, restore a clean VM snapshot first.

### 3. Open the website

From a browser on the VM, visit `http://localhost/`.

From another machine that can reach the VM, use `http://<VM-IP>/`. VM networking and any host or cloud firewall must also allow HTTP access. A successful deployment should display eight sample product cards.

## Verify the Deployment

Run these checks on the CentOS VM:

```bash
# Confirm services are running and enabled at boot
sudo systemctl is-active firewalld mariadb httpd
sudo systemctl is-enabled firewalld mariadb httpd

# Validate Apache configuration and inspect firewall rules
sudo apachectl configtest
sudo firewall-cmd --zone=public --list-all

# Confirm the database contains eight products
sudo mysql -e 'SELECT COUNT(*) AS product_count FROM ecomdb.products;'

# Check the HTTP response, if curl is installed
curl -I http://localhost/
```

Check the rendered product list in the browser as well: an HTTP response alone does not prove the database connection works.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Package installation fails | Network access, package repositories, and the CentOS release |
| Website files cannot be found | Run from the repository root; a previous run may already have moved the website contents |
| Database or user already exists | Restore a fresh VM snapshot; repeat-run handling is not implemented |
| Page reports a database error | MariaDB status, database creation, deployed `.env` values, and the inserted PHP loader |
| Apache fails to start | `sudo apachectl configtest` and `sudo journalctl -u httpd -n 50 --no-pager` |
| Website is unreachable remotely | VM IP, network mode, active firewall zone, and host or cloud firewall rules |
| Permission errors occur | File ownership and SELinux contexts; inspect logs and correct contexts rather than disabling SELinux |

Apache's error log is typically available at `/var/log/httpd/error_log`.

## Current Limitations and Next Steps

- **Protect configuration:** The script writes fixed demo credentials to `.env` inside the web root without adding an Apache access restriction. Move secrets outside the served directory and restrict their permissions.
- **Apply least privilege:** The application user currently receives privileges on all databases. Limit access to the product data it needs.
- **Keep MariaDB local:** The application connects to `localhost`, so opening the database firewall port is unnecessary for this design.
- **Handle failures:** Add prerequisite checks, explicit error handling, and a final deployment health check.
- **Support repeat runs:** Copy application files instead of moving them, resolve paths from the script location, and handle existing database objects without duplicating seed data.
- **Simplify deployment:** Store the environment loader in the PHP source instead of inserting it at a fixed line number, and use one authoritative SQL seed file.
- **Record reproducible results:** Document the exact tested OS release, add a screenshot of the deployed catalog, and run ShellCheck in CI.

## Skills Practiced

- Bash scripting, heredocs, and command sequencing
- Linux package management with `dnf`
- Service management with `systemctl`
- Firewall configuration with `firewall-cmd`
- Database initialization and SQL seed data
- Apache and PHP configuration
- Text manipulation with `sed`
- Environment-based application configuration

## Acknowledgments

This project was developed as part of the **KodeKloud Beginner Scripting course**. The focus of this repository is deployment automation and Linux administration using a sample application from the learning exercise.

Before adding a repository-wide license, verify the reuse terms for the course-provided application and bundled third-party assets.
