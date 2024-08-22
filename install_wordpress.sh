#!/bin/bash

# Update package list and install necessary packages
sudo apt update
sudo apt install -y nginx mysql-server mysql-client php-fpm php-mysql php-xml php-mbstring php-curl php-zip php-gd php-imagick wget unzip

# Secure MySQL installation (Optional)
# Uncomment the following line if you want to run the MySQL secure installation interactively
# sudo mysql_secure_installation

# Create a MySQL database and user for WordPress
DB_NAME="wordpress_db"
DB_USER="wp_user"
DB_PASSWORD="password123"

sudo mysql -e "CREATE DATABASE ${DB_NAME};"
sudo mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Download and extract WordPress
cd /var/www/
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xvzf latest.tar.gz
sudo mv wordpress mywordpresssite

# Configure WordPress
cd /var/www/mywordpresssite
sudo cp wp-config-sample.php wp-config.php

sudo sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
sudo sed -i "s/username_here/${DB_USER}/" wp-config.php
sudo sed -i "s/password_here/${DB_PASSWORD}/" wp-config.php

# Set correct permissions
sudo chown -R www-data:www-data /var/www/mywordpresssite
sudo find /var/www/mywordpresssite/ -type d -exec chmod 750 {} \;
sudo find /var/www/mywordpresssite/ -type f -exec chmod 640 {} \;

# Configure Nginx
NGINX_CONF="/etc/nginx/sites-available/mywordpresssite"
sudo bash -c "cat > ${NGINX_CONF}" <<EOF
server {
    listen 8080;
    server_name your_public_ip;

    root /var/www/mywordpresssite;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Replace 'your_public_ip' with the server's public IP
PUBLIC_IP=$(curl -s ifconfig.me)
sudo sed -i "s/your_public_ip/${PUBLIC_IP}/" ${NGINX_CONF}

# Enable the Nginx site and reload the configuration
sudo ln -s /etc/nginx/sites-available/mywordpresssite /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Output completion message
echo "WordPress has been installed. Open http://${PUBLIC_IP} in your browser to complete the setup."

