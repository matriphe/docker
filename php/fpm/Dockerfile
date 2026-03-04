ARG PHP_VERSION=8.4
ARG WORKDIR=/var/www/html
ARG USER=www-data
ARG DEBIAN_FRONTEND=noninteractive

FROM docker.io/library/composer:latest AS composer

FROM docker.io/library/php:${PHP_VERSION}-fpm-trixie AS php_fpm
ARG WORKDIR=/var/www/html
ARG USER=www-data

LABEL maintainer="Muhammad Zamroni <halo@matriphe.com>"

ARG RUNTIME_DEPS="git pkg-config libfcgi-bin zip unzip curl \
    libzip5 libpng16-16 libwebp7 libxpm4 libjpeg62-turbo libfreetype6 libxml2 libicu76 libonig5 libcurl4"

ARG BUILD_DEPS="zlib1g-dev libzip-dev libpng-dev libwebp-dev libxpm-dev libjpeg-dev libfreetype-dev libxml2-dev libicu-dev libonig-dev libcurl4-openssl-dev"

ARG PHP_EXTENSIONS="pdo pdo_mysql xml mbstring exif bcmath intl zip curl"
ARG PECL_EXTENSIONS="apcu excimer"
ARG JOB_NUM=""
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
    apt-get update; \
    apt-get install -y --no-install-recommends ${RUNTIME_DEPS}; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        ${BUILD_DEPS}; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j"${JOB_NUM:-$(nproc)}" gd opcache ${PHP_EXTENSIONS}

RUN set -eux; \
    pecl install ${PECL_EXTENSIONS}; \
    docker-php-ext-enable ${PECL_EXTENSIONS}

RUN set -eux; \
    apt-get purge -y $PHPIZE_DEPS ${BUILD_DEPS}; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN set -eux; \
    (groupadd -g 33 "${USER}" 2>/dev/null || true); \
    (useradd -u 33 -g "${USER}" -s /bin/bash -m "${USER}" 2>/dev/null || true); \
    chown -R "${USER}:${USER}" "${WORKDIR}"; \
    chmod -R 755 "${WORKDIR}"

COPY config/php/php.ini /usr/local/etc/php/php.ini
COPY config/php/www.conf /usr/local/etc/php-fpm.d/www.conf

RUN set -eux; \
    sed -i "s/www-data/${USER}/g" /usr/local/etc/php-fpm.d/www.conf

EXPOSE ${PHP_FPM_PORT}
