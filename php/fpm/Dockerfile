ARG PHP_VERSION=8.4
ARG WORKDIR=/var/www/html
ARG USER=www-data

FROM docker.io/library/composer:latest AS composer

FROM docker.io/library/php:${PHP_VERSION}-fpm-alpine AS php_fpm
ARG WORKDIR=/var/www/html
ARG USER=www-data

LABEL maintainer="Muhammad Zamroni <halo@matriphe.com>"

ARG RUNTIME_DEPS="git pkgconf fcgi zip unzip curl \
    libzip libpng libwebp libxpm libjpeg-turbo freetype libxml2 icu-libs oniguruma libcurl"

ARG PHP_EXTENSIONS="pdo pdo_mysql xml mbstring exif bcmath intl zip curl gd opcache"
ARG PECL_EXTENSIONS="apcu excimer opentelemetry"
# Build concurrency argument to speed up extension compilation 
# on multi-core systems (e.g., -j$(nproc))
ARG JOB_NUM=""

# JIT is disabled because it often causes segmentation faults when building 
# for ARM64 via QEMU emulation on x86_64 CI runners.
ARG PHP_OPCACHE_ENABLE=1
ARG PHP_OPCACHE_JIT=0
ARG PHP_OPCACHE_ENABLE_JIT=0
ARG COMPOSER_CACHE_DIR=/tmp/composer-cache

ENV PHP_OPCACHE_ENABLE=${PHP_OPCACHE_ENABLE} \
    PHP_OPCACHE_JIT=${PHP_OPCACHE_JIT} \
    PHP_OPCACHE_ENABLE_JIT=${PHP_OPCACHE_ENABLE_JIT} \
    PHP_FPM_PORT=9000 \
    WORKDIR=${WORKDIR} \
    USER=${USER} \
    COMPOSER_CACHE_DIR=${COMPOSER_CACHE_DIR}

COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR ${WORKDIR}

# Layer 1: Install runtime dependencies
RUN apk add --no-cache ${RUNTIME_DEPS}

# Layer 2: Download and configure extension installer, install all extensions
RUN set -eux; \
    curl -sSL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions; \
    chmod +x /usr/local/bin/install-php-extensions; \
    install-php-extensions ${PHP_EXTENSIONS} ${PECL_EXTENSIONS}; \
    rm /usr/local/bin/install-php-extensions; \
    rm -rf /tmp/* /var/tmp/*

# Layer 3: Create application user (UID 82 is Alpine default for www-data)
# This ensures consistent file permissions when sharing volumes with other Alpine containers
RUN set -eux; \
    (addgroup -g 82 -S "${USER}" 2>/dev/null || true); \
    (adduser -u 82 -D -S -G "${USER}" "${USER}" 2>/dev/null || true); \
    chown -R "${USER}:${USER}" "${WORKDIR}"; \
    chmod -R 755 "${WORKDIR}"

COPY config/php/php.ini /usr/local/etc/php/php.ini
COPY config/php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php/fpm/config/php-instrumentation.ini /usr/local/etc/php/conf.d/opentelemetry.ini

RUN set -eux; \
    sed -i "s/www-data/${USER}/g" /usr/local/etc/php-fpm.d/www.conf

EXPOSE ${PHP_FPM_PORT}
