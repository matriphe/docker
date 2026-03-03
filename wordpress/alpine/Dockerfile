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

# Copy php-fpm configuration
COPY --chown=www-data:www-data config/www.conf /usr/local/etc/php-fpm.d/www.conf
# Copy uploads configuration
COPY --chown=www-data:www-data config/uploads.ini /usr/local/etc/php/conf.d/uploads.ini

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
    nano && \
    \
    # Change directory to WordPress surce code
    cd /usr/src/wordpress && \
    \
    # Allow Composer to extends the functionality of Composer to support custom WordPress plugin installation path using `www-data` user
    su -s /bin/sh -c "composer config --no-interaction allow-plugins.composer/installers true" www-data && \
    \
    # Install S3-Uploads plugin from https://github.com/humanmade/S3-Uploads usng Composer using `www-data` user
    su -s /bin/sh -c "composer require humanmade/s3-uploads:dev-master --no-interaction" www-data && \
    \
    # Create plugin page for custom S3 endpoint
    mkdir -p wp-content/mu-plugins && \
    # Set owner to `www-data`
    chown ${USER}:${USER} wp-content/mu-plugins

# Set workdir
WORKDIR ${WORDPRESS_ROOT}

# Set volumes (use explicit path since VOLUME doesn't expand env vars)
VOLUME ${WORDPRESS_ROOT}
