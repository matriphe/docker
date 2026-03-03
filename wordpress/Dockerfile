ARG WORKDIR=/var/www/wordpress
ARG PHP_VERSION=8.4

FROM wordpress:cli-php${PHP_VERSION} AS wpcli

FROM wordpress:6-php${PHP_VERSION}-fpm-alpine AS wordpress

# Re-declare ARGs that we need in this stage (they don't carry over from global scope)
ARG WORKDIR=/var/www/wordpress
ARG USER=www-data

# Copy wp-cli from the selected stage
COPY --from=wpcli /usr/local/bin/wp /usr/local/bin/wp
# Copy Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy shared PHP and php-fpm configuration
COPY --chown=www-data:www-data config/php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY --chown=www-data:www-data config/php/php.ini /usr/local/etc/php/php.ini

# Define new WordPress path using the ARG from this stage
ENV WORDPRESS_ROOT=$WORKDIR
ENV USER=$USER

RUN \
    # Copy WordPress files to the new path
    mkdir -p ${WORDPRESS_ROOT} && \
    cp -r /var/www/html/* ${WORDPRESS_ROOT} && \
    rm -rf /var/www/html && \
    \
    # Update PHP-FPM configuration
    sed -i "s|/var/www/html|${WORDPRESS_ROOT}|g" /usr/local/etc/php-fpm.d/www.conf && \
    \
    # Install some tools
    apk add --no-cache \
    # jq for JSON parsing
    jq \
    # nano for text editor
    nano

# Set workdir
WORKDIR ${WORDPRESS_ROOT}

# Set volumes (use explicit path since VOLUME doesn't expand env vars)
VOLUME ${WORDPRESS_ROOT}
