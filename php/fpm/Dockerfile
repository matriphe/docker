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

ARG BUILD_DEPS="zlib-dev libzip-dev libpng-dev libwebp-dev libxpm-dev libjpeg-turbo-dev freetype-dev libxml2-dev icu-dev oniguruma-dev curl-dev"

ARG PHP_EXTENSIONS="pdo pdo_mysql xml mbstring exif bcmath intl zip curl"
ARG PECL_EXTENSIONS="apcu excimer"
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

RUN set -eux; \
    apk add --no-cache ${RUNTIME_DEPS}; \
    apk add --no-cache autoconf automake libtool make g++ gcc musl-dev; \
    curl -sSL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions; \
    chmod +x /usr/local/bin/install-php-extensions; \
    install-php-extensions gd opcache ${PHP_EXTENSIONS} ${PECL_EXTENSIONS}; \
    # Install OpenTelemetry extension explicitly
    pecl install opentelemetry; \
    docker-php-ext-enable opentelemetry; \
    # Remove build dependencies and clean up
    apk del --no-cache autoconf automake libtool make g++ gcc musl-dev; \
    rm /usr/local/bin/install-php-extensions; \
    rm -rf /tmp/* /var/tmp/*

# We use UID 82 (the Alpine default for www-data) to ensure consistent 
# file permissions when sharing volumes with the Nginx container, 
# which is also based on Alpine.
RUN set -eux; \
    (addgroup -g 82 -S "${USER}" 2>/dev/null || true); \
    (adduser -u 82 -D -S -G "${USER}" "${USER}" 2>/dev/null || true); \
    chown -R "${USER}:${USER}" "${WORKDIR}"; \
    chmod -R 755 "${WORKDIR}"

COPY config/php.ini /usr/local/etc/php/php.ini
COPY config/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php/fpm/config/php-instrumentation.ini /usr/local/etc/php/conf.d/opentelemetry.ini

RUN set -eux; \
    sed -i "s/www-data/${USER}/g" /usr/local/etc/php-fpm.d/www.conf

EXPOSE ${PHP_FPM_PORT}
