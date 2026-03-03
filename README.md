# Docker

This is a collection of `Dockerfiles` to build custom images used by Muhammad Zamroi (matriphe).

## PHP-FPM

Custom PHP-FPM image based on Debian trixie (`php:8.4-fpm-trixie`), built from [`php/fpm`](php/fpm) with:
- Custom PHP config from [`php/fpm/config/php.ini`](php/fpm/config/php.ini)
- Custom FPM pool config from [`php/fpm/config/www.conf`](php/fpm/config/www.conf)
- Common extensions and tools for app workloads

### Installed Extensions

- Core/build extensions: `gd`, `opcache`, `pdo`, `pdo_mysql`, `xml`, `mbstring`, `exif`, `bcmath`, `intl`, `zip`, `curl`
- PECL extensions: `apcu`, `excimer`

### Usage

```console
docker pull ghcr.io/matriphe/docker:php-fpm-php8.4-trixie
```

## WordPress

Custom WordPress image based on Alpine (`wordpress:6-php8.4-fpm-alpine`), with:
- `wp-cli` available in the container
- Composer available in the container
- Custom PHP-FPM pool config from [`wordpress/config/www.conf`](wordpress/config/www.conf)
- Upload limits from [`wordpress/config/uploads.ini`](wordpress/config/uploads.ini) (`20M`)

### Usage

```console
docker pull ghcr.io/matriphe/docker:wp-6-php8.4-fpm-alpine
```

## CI / Publish Schedule

The GitHub Actions Docker publish workflow runs on Friday at `04:00 UTC` (`05:00/06:00 Europe/Berlin`, depending on DST).
