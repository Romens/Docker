FROM php:8.3-fpm

ARG UID
ARG GID

ENV UID=${UID}
ENV GID=${GID}

RUN mkdir -p /var/www/html

WORKDIR /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && mkdir -p /var/www/.npm \
    && chown -R www-data:www-data /var/www/.npm

# Install dependencies for Puppeteer/Chromium
RUN apt-get update && apt-get install -y \
    ca-certificates \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libgcc1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    lsb-release \
    wget \
    xdg-utils \
    chromium \
    chromium-driver

# Install necessary packages for PHP extensions
RUN apt-get update && apt-get install -y \
        git \
        unzip \
        libyaml-dev \
        openssh-client \
        libfreetype6-dev \
        libjpeg-dev \
        libpng-dev \
        libzip-dev \
        libwebp-dev \
        libxpm-dev \
        libpq-dev \
        autoconf \
        automake \
        libtool \
        build-essential \
        && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
        && docker-php-ext-install gd \
        && docker-php-ext-configure zip \
        && docker-php-ext-install pdo pdo_mysql pdo_pgsql zip pcntl \
        && pecl install yaml \
        && docker-php-ext-enable yaml

# Install xdebug
RUN apt-get update && apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        && pecl install xdebug \
        && docker-php-ext-enable xdebug \
        && pecl clear-cache

# Install redis extension
RUN apt-get update && apt-get install -y \
        autoconf \
        build-essential \
        && mkdir -p /usr/src/php/ext/redis \
        && curl -L https://github.com/phpredis/phpredis/archive/5.3.4.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 \
        && echo 'redis' >> /usr/src/php-available-exts \
        && docker-php-ext-install redis

# Install pcov extension for code coverage
RUN pecl install pcov \
        && docker-php-ext-enable pcov

#ENV XDEBUG_MODE=coverage
ENV PHP_IDE_CONFIG="serverName=romens.local"
ENV PSYSH_CONFIG_DIR="/tmp"

COPY xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Copy logging configuration files
COPY php-fpm-logging.conf /usr/local/etc/php-fpm.d/www.conf
COPY logging_prepend.php /var/www/html/logging_prepend.php

# Create logs directory and set permissions
RUN mkdir -p /var/www/html/storage/logs && \
    chown -R www-data:www-data /var/www/html/storage/logs && \
    chmod -R 755 /var/www/html/storage/logs

# Create Git config directory and set permissions
RUN mkdir -p /var/www/.git && \
    chown -R www-data:www-data /var/www/.git && \
    chmod -R 755 /var/www/.git

# Create PsySH config directory and set permissions
RUN mkdir -p /var/www/.config/psysh && \
    chown -R www-data:www-data /var/www/.config && \
    chmod -R 755 /var/www/.config

# Create directory for puppeteer cache and set permissions
RUN mkdir -p /var/www/.cache/puppeteer && \
    chown -R www-data:www-data /var/www/.cache && \
    chmod -R 755 /var/www/.cache

# Configure Git
RUN git config --global --add safe.directory '/var/www/html' && \
    git config --global user.email "santa_claus@romens.email" && \
    git config --global user.name "Santa Claus"

# install NVM and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
RUN export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install 20
RUN export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm use 20
RUN export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm alias default 20
RUN export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && npm install -g yarn puppeteer


USER www-data

CMD ["php-fpm", "-y", "/usr/local/etc/php-fpm.conf", "-R"]
