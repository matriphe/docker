# Docker

This is a collection of `Dockerfiles` to build custom images used by Muhammad Zamroi (matriphe).

## OpenResty

Custom OpenResty image based on `openresty/openresty:alpine`, built from [`nginx`](nginx). OpenResty is Nginx with Lua scripting capabilities, providing enhanced flexibility and performance.

### Features
- Same configuration compatibility as Nginx
- Lua scripting support for custom logic
- Maintains all proxy and security settings from original Nginx config

### Usage

```console
docker pull ghcr.io/matriphe/docker/nginx:openresty
```

## PHP-FPM

Custom PHP-FPM image based on Alpine (`php:8.4-fpm-alpine`), built from [`php/fpm`](php/fpm) with:
- Shared PHP config from [`config/php/php.ini`](config/php/php.ini)
- Shared FPM pool config from [`config/php/www.conf`](config/php/www.conf)
- Common extensions and tools for app workloads

### Installed Extensions

- Core/build extensions: `gd`, `opcache`, `pdo`, `pdo_mysql`, `xml`, `mbstring`, `exif`, `bcmath`, `intl`, `zip`, `curl`
- PECL extensions: `apcu`, `excimer`

### Usage

```console
docker pull ghcr.io/matriphe/docker/php:8.4-fpm
```

## WordPress

Custom WordPress image based on Alpine (`wordpress:6-php8.4-fpm-alpine`), with:
- `wp-cli` available in the container
- Composer available in the container
- Shared PHP config from [`config/php/php.ini`](config/php/php.ini)
- Shared FPM pool config from [`config/php/www.conf`](config/php/www.conf)

### Usage

```console
docker pull ghcr.io/matriphe/docker/wordpress:php8.4-fpm
```

## CI / Publish Schedule

The GitHub Actions Docker publish workflow runs on Friday at `04:00 UTC` (`05:00/06:00 Europe/Berlin`, depending on DST) and publishes:
- `ghcr.io/matriphe/docker/nginx:openresty`
- `ghcr.io/matriphe/docker/php:8.4-fpm`
- `ghcr.io/matriphe/docker/wordpress:php8.4-fpm`
