# Docker

This is a collection of `Dockerfiles` to build custom images used by Muhammad Zamroi (matriphe).

## Nginx Amplify

The Nginx Amplify is compiled from [their official repository](https://github.com/nginxinc/docker-nginx-amplify).

### Usage

```console
docker pull ghcr.io/matriphe/docker:nginx-amplify-alpine-latest
```

## PHP

The PHP fpm image that displays `phpinfo()` as `index.php` file that is useful to check if Nginx works with PHP-fpm.

```console
docker pull ghcr.io/matriphe/docker:php-fpm-info-alpine-8.3
```

### Usage

Make sure to point the `root` directory on Nginx to `/var/www/html`.

Example of Nginx config is the following:

```conf
server {
    listen 80;
    server_name _; # Domain name
    root /var/www/html; # The location of index.php
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
       fastcgi_pass   php:9000; # Update this part
       fastcgi_index  index.php;
       fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
       include        fastcgi_params;
    }
}
```

## CI / Publish Schedule

The GitHub Actions Docker publish workflow runs on Friday at `04:00 UTC` (`05:00/06:00 Europe/Berlin`, depending on DST).

## WordPress

Custom WordPress image based on `wordpress:6-php8.4-fpm-alpine`, with:
- `wp-cli` available in the container
- Composer available in the container
- Custom PHP-FPM pool config from [`wordpress/alpine/config/www.conf`](wordpress/alpine/config/www.conf)
- Upload limits from [`wordpress/alpine/config/uploads.ini`](wordpress/alpine/config/uploads.ini) (`20M`)

### Usage

```console
docker pull ghcr.io/matriphe/docker:wp-6-php8.4-fpm-alpine
```
