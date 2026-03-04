ARG WORKDIR=/var/www/wordpress
ARG PHP_VERSION=8.4

FROM docker.io/library/wordpress:cli-php${PHP_VERSION} AS wp_cli
FROM docker.io/library/composer:latest AS composer_bin
FROM docker.io/library/wordpress:6-php${PHP_VERSION}-fpm-alpine AS wordpress

ARG WORKDIR=/var/www/wordpress
ARG USER=www-data

ENV WORDPRESS_ROOT=${WORKDIR} \
    USER=${USER}

COPY --from=wp_cli /usr/local/bin/wp /usr/local/bin/wp
COPY --from=composer_bin /usr/bin/composer /usr/bin/composer

COPY --chown=www-data:www-data config/php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY --chown=www-data:www-data config/php/php.ini /usr/local/etc/php/php.ini

RUN set -eux; \
    mkdir -p "${WORDPRESS_ROOT}"; \
    cp -r /var/www/html/* "${WORDPRESS_ROOT}"; \
    rm -rf /var/www/html; \
    sed -i "s|/var/www/html|${WORDPRESS_ROOT}|g" /usr/local/etc/php-fpm.d/www.conf; \
    apk add --no-cache jq nano

WORKDIR ${WORDPRESS_ROOT}

VOLUME ${WORDPRESS_ROOT}
