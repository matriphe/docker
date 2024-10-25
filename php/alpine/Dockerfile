FROM php:8.3-fpm-alpine

RUN \
    # Update repository
    apk update && apk upgrade &&  \
    # Install fcgiwrap
    apk add --no-cache fcgiwrap && \
    # Clean up
    rm -rf /var/cache/apk/* && \
    \
    # Add phpinfo to index.php so it can be used to show default page,
    # to be used as default image with Nginx to prove the PHP is working.
    echo '<?php phpinfo(); ?>' > /var/www/html/index.php
