ARG PHP_VERSION=8.4
ARG WORKDIR=/var/www/html

FROM docker.io/library/composer:latest AS composer

FROM docker.io/library/php:${PHP_VERSION}-fpm-alpine

LABEL maintainer="Muhammad Zamroni <halo@matriphe.com>"

# Define runtime dependencies (must be kept in final image)
ARG RUNTIME_DEPS="git pkgconf fcgi zip unzip curl \
    libzip libpng libwebp libxpm libjpeg-turbo freetype libxml2 icu-libs oniguruma libcurl"

# Define build dependencies (can be removed after compilation)
ARG BUILD_DEPS="zlib-dev libzip-dev libpng-dev libwebp-dev libxpm-dev libjpeg-turbo-dev freetype-dev libxml2-dev icu-dev oniguruma-dev curl-dev"

# List all PHP extensions to install using docker-php-ext-install, except gd and opcache (these are installed by default)
ARG PHP_EXTENSIONS="pdo pdo_mysql xml mbstring exif bcmath intl zip curl"

# List all PECL extensions to install
ARG PECL_EXTENSIONS="apcu excimer"

# Build concurrency argument
ARG JOB_NUM=""

# Default user
ARG USER=www-data

# OPcache arguments to disable JIT that causes problem on QEMU ARM64
ARG PHP_OPCACHE_ENABLE=1
ARG PHP_OPCACHE_JIT=0
ARG PHP_OPCACHE_ENABLE_JIT=0

ENV PHP_OPCACHE_ENABLE=${PHP_OPCACHE_ENABLE} \
    PHP_OPCACHE_JIT=${PHP_OPCACHE_JIT} \
    PHP_OPCACHE_ENABLE_JIT=${PHP_OPCACHE_ENABLE_JIT}

# Set default port
ENV PHP_FPM_PORT=9000

# Set WORKDIR and USER as environment variables so they're available in RUN commands
ARG WORKDIR=/var/www/html
ENV WORKDIR=${WORKDIR}

# Set USER as environment variable so it's available in RUN commands
ARG USER=www-data
ENV USER=${USER}

# Copy Composer
ARG COMPOSER_CACHE_DIR=/tmp/composer-cache
ENV COMPOSER_CACHE_DIR=${COMPOSER_CACHE_DIR}

COPY --from=composer /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR ${WORKDIR}

# Install dependencies and extensions
RUN apk add --no-cache ${RUNTIME_DEPS} \
    && apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    ${BUILD_DEPS} \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j${JOB_NUM:-$(nproc)} \
    gd opcache ${PHP_EXTENSIONS} \
    && pecl install ${PECL_EXTENSIONS} \
    && docker-php-ext-enable ${PECL_EXTENSIONS} \
    && apk del .build-deps \
    && rm -rf /tmp/* /var/tmp/*

# Layer 6: Create user and group
# Using UID/GID 33 which is the standard for www-data in Debian Linux for consistency
RUN addgroup -g 33 -S ${USER} 2>/dev/null || true \
    && adduser -u 33 -D -S -G ${USER} ${USER} 2>/dev/null || true \
    && chown -R ${USER}:${USER} ${WORKDIR} && chmod -R 755 ${WORKDIR}

# Copy shared PHP configuration files
COPY config/php/php.ini /usr/local/etc/php/php.ini
COPY config/php/www.conf /usr/local/etc/php-fpm.d/www.conf

# Layer 7: Update PHP-FPM pool configuration to use the specified user
RUN sed -i "s/www-data/${USER}/g" /usr/local/etc/php-fpm.d/www.conf

# Expose ports
EXPOSE ${PHP_FPM_PORT}

