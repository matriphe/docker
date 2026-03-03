ARG PHP_VERSION=8.4
ARG WORKDIR=/var/www/html
ARG DEBIAN_FRONTEND=noninteractive

FROM docker.io/library/composer:latest AS composer

FROM docker.io/library/php:${PHP_VERSION}-fpm-trixie

LABEL maintainer="Muhammad Zamroni <halo@matriphe.com>"

# Define runtime dependencies (must be kept in final image)
ARG RUNTIME_DEPS="git pkg-config libfcgi-bin zip unzip curl \
    libzip5 libpng16-16 libwebp7 libxpm4 libjpeg62-turbo libfreetype6 libxml2 libicu76 libonig5 libcurl4"

# Define build dependencies (can be removed after compilation)
ARG BUILD_DEPS="zlib1g-dev libzip-dev libpng-dev libwebp-dev libxpm-dev libjpeg-dev libfreetype-dev libxml2-dev libicu-dev libonig-dev libcurl4-openssl-dev"

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

# Layer 1: Install runtime dependencies (cache invalidated only when RUNTIME_DEPS changes)
RUN apt-get update \
    && apt-get install -y --no-install-recommends ${RUNTIME_DEPS} \
    && rm -rf /var/lib/apt/lists/*

# Layer 2: Install build dependencies and tools (cache invalidated only when BUILD_DEPS changes)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    $PHPIZE_DEPS \
    ${BUILD_DEPS} \
    && rm -rf /var/lib/apt/lists/*

# Layer 3: Configure and compile PHP extensions (cache invalidated only when PHP_EXTENSIONS changes)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j${JOB_NUM:-$(nproc)} \
    gd opcache ${PHP_EXTENSIONS}

# Layer 4: Install and enable PECL extensions (cache invalidated only when PECL_EXTENSIONS changes)
RUN pecl install ${PECL_EXTENSIONS} \
    && docker-php-ext-enable ${PECL_EXTENSIONS}

# Layer 5: Clean up build tools and development libraries (keep runtime libraries)
RUN apt-get purge -y $PHPIZE_DEPS ${BUILD_DEPS} \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Layer 6: Create user and group (cache invalidated only when USER changes)
# Using UID/GID 33 which is the standard for www-data in Debian Linux
# This ensures consistency across systems and proper file ownership
# The || true ensures the command succeeds even if user/group already exists
RUN (groupadd -g 33 ${USER} 2>/dev/null || true) \
    && (useradd -u 33 -g ${USER} -s /bin/bash -m ${USER} 2>/dev/null || true) \
    && chown -R ${USER}:${USER} ${WORKDIR} && chmod -R 755 ${WORKDIR}

# Copy PHP configuration files (moved to end — only invalidates these final layers)
COPY config/php.ini /usr/local/etc/php/php.ini
COPY config/www.conf /usr/local/etc/php-fpm.d/www.conf

# Layer 7: Update PHP-FPM pool configuration to use the specified user (fast, isolated layer)
RUN sed -i "s/www-data/${USER}/g" /usr/local/etc/php-fpm.d/www.conf

# Expose ports
EXPOSE ${PHP_FPM_PORT}
