#!/bin/bash
set -eo pipefail

# Enable PHP
add-apt-repository -y ppa:ondrej/php

# Enable nginx repo
wget -q http://nginx.org/packages/keys/nginx_signing.key
cat nginx_signing.key | sudo apt-key add -
add-apt-repository 'deb http://nginx.org/packages/ubuntu/ xenial nginx'

# Update installed packages
apt-get -y update

# Install nginx and PHP
DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
apt install -y php
echo
echo
echo
php --version
echo
echo
echo
apt-get -y install nginx php$PHP_VERSION-fpm php$PHP_VERSION-mysql \
	php$PHP_VERSION-bcmath php$PHP_VERSION-gd php$PHP_VERSION-xml \
    php$PHP_VERSION-zip php$PHP_VERSION-mbstring php$PHP_VERSION-curl \
    htop nano net-tools zip unzip openssh-server libssl1.1
echo
apt-get -y update
apt-get install -y -f

mkdir -p /var/www
chown -R app:app /var/www
mkdir -p /var/www/.ssh
ln -sf /dev/stdout /var/log/nginx/access.log
ln -sf /dev/stderr /var/log/nginx/error.log
rm /etc/nginx/conf.d/*

# Change max execution time to 180 seconds
sed -ri 's/(max_execution_time =) ([2-9]+)/\1 180/' /etc/php/$PHP_VERSION/fpm/php.ini

# Max memory to allocate for each php-fpm process
sed -ri 's/(memory_limit =) ([0-9]+)/\1 1024/' /etc/php/$PHP_VERSION/fpm/php.ini

# Set the timezone
sed -ri "s@^;date\.timezone\s+.*@date\.timezone=${TZ}@" /etc/php/$PHP_VERSION/fpm/php.ini

# Install ioncube loader
cd /tmp && curl -o ioncube.zip http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.zip && \
    echo "Step 1" && \
    unzip ioncube.zip && \
    echo "Step 2" && \
    rm ioncube.zip && \
    echo "Step 3" && \
    mkdir -p /usr/lib/php/ioncube && \
    echo "Step 4" && \
    cp /tmp/ioncube/ioncube_loader_lin_$PHP_VERSION.so /usr/lib/php/ioncube/. && \
    echo "Step 5" && \
    echo "zend_extension = /usr/lib/php/ioncube/ioncube_loader_lin_${PHP_VERSION}.so" \
    > /etc/php/${PHP_VERSION}/fpm/conf.d/00-ioncube.ini && \
    echo "Step 6" && \
    cp /etc/php/${PHP_VERSION}/fpm/conf.d/00-ioncube.ini /etc/php/${PHP_VERSION}/cli/conf.d/. && \
    echo "Step 7"

# Install Dockerize
DOCKERIZE_VERSION="v0.7.0"
wget -qO - https://github.com/jwilder/dockerize/releases/download/v0.7.0/dockerize-alpine-linux-amd64-v0.7.0.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Cleanup
chmod +x /build/cleanup.sh
/build/cleanup.sh
