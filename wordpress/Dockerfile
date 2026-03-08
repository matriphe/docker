ARG WORKDIR=/var/www/wordpress
ARG PHP_VERSION=8.4

FROM docker.io/library/wordpress:cli-php${PHP_VERSION} AS wp_cli
FROM docker.io/library/composer:latest AS composer_bin
FROM docker.io/library/wordpress:6-php${PHP_VERSION}-fpm-alpine AS wordpress

ARG WORKDIR=/var/www/wordpress
ARG USER=www-data

LABEL maintainer="Muhammad Zamroni <halo@matriphe.com>"

ENV WORDPRESS_ROOT=${WORKDIR} \
    USER=${USER}

# Copy binary dependencies from other stages
COPY --from=wp_cli /usr/local/bin/wp /usr/local/bin/wp
COPY --from=composer_bin /usr/bin/composer /usr/bin/composer

# Copy config files before the RUN step to prevent them from invalidating the WordPress base layer cache
COPY --chown=www-data:www-data config/php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY --chown=www-data:www-data config/php/php.ini /usr/local/etc/php/php.ini
COPY --chown=www-data:www-data wordpress/config/wp-instrumentation.ini /usr/local/etc/php/conf.d/opentelemetry.ini

# Configure WordPress directory and install additional tools
RUN set -eux; \
    mkdir -p "${WORDPRESS_ROOT}"; \
    cp -r /var/www/html/* "${WORDPRESS_ROOT}"; \
    rm -rf /var/www/html; \
    sed -i "s|/var/www/html|${WORDPRESS_ROOT}|g" /usr/local/etc/php-fpm.d/www.conf

# Install utility and OpenTelemetry extensions
RUN set -eux; \
    apk add --no-cache jq nano curl; \
    curl -sSL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions; \
    chmod +x /usr/local/bin/install-php-extensions; \
    install-php-extensions opentelemetry; \
    rm /usr/local/bin/install-php-extensions; \
    rm -rf /tmp/* /var/tmp/*

WORKDIR ${WORDPRESS_ROOT}

VOLUME ${WORDPRESS_ROOT}
