FROM php:8.3-fpm-alpine

# Add phpinfo to index.php so it can be used to show default page,
# to be used as default image with Nginx to prove the PHP is working.
RUN echo '<?php phpinfo(); ?>' > /var/www/html/index.php
