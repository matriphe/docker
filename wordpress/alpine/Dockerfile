FROM wordpress:6-php8.3-fpm-alpine

# Define new WordPress path
ENV WORDPRESS_ROOT /var/www/wordpress

# Copy WordPress files to the new path
RUN mkdir -p ${WORDPRESS_ROOT} && \
    cp -r /var/www/html/* ${WORDPRESS_ROOT} && \
    rm -rf /var/www/html

WORKDIR ${WORDPRESS_ROOT}

# Update PHP-FPM configuration
RUN sed -i "s|/var/www/html|${WORDPRESS_ROOT}|g" /usr/local/etc/php-fpm.d/www.conf
