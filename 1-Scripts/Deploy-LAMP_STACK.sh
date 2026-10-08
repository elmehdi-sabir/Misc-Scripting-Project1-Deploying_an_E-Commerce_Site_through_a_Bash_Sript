#!/bin/bash


# dnf update -y
dnf update -y

# Install, start and enable firewalld
dnf install -y firewalld
systemctl start firewalld
systemctl enable firewalld

# Deploy Database

## 1. Install, start and enable MariaDB server
dnf install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb

## 2. Configure firewalld for Database
firewall-cmd --permanent --zone=public --add-port=3306/tcp 
firewall-cmd --reload

## 3. Configure database
mysql << EOF
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;
EOF

## 4. Create db-load-script.sql
cat > db-load-script.sql << EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;
INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");
EOF

mysql < db-load-script.sql

# Deploy and Configure Web Server

## 1. Install required packages
dnf install -y httpd php php-mysqlnd
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --reload

## 2. Configure httpd service
sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf


## 3. Start and enable httpd service
systemctl start httpd
systemctl enable httpd

## 4. Download Application Code
mv ./2-Website/* /var/www/html/

## 5. Create and configure an .env file
touch /var/www/html/.env

cat > /var/www/html/.env << EOF
DB_HOST=localhost
DB_USER=ecomuser
DB_PASSWORD=ecompassword
DB_NAME=ecomdb
EOF

## 6. Update index.php (add function to code)
## copy function block to file php_code 

cat > php_code << 'EOF'
			function loadEnv($path)
			{
				if (!file_exists($path)) {
					return false;
				}

				$lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
				foreach ($lines as $line) {
					if (strpos(trim($line), '#') === 0) {
						continue;
					}

					list($name, $value) = explode('=', $line, 2);
					$name = trim($name);
					$value = trim($value);
					putenv(sprintf('%s=%s', $name, $value));
				}
				return true;
			}

			// Load environment variables from .env file
			loadEnv(__DIR__ . '/.env');
EOF

## insert it to index.php using sed tool after line 107
sed -i '107r php_code' /var/www/html/index.php 
