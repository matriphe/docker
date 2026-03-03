# Docker

This is a collection of `Dockerfiles` to build custom images used by Muhammad Zamroi (matriphe).

## NGINX (OpenTelemetry)

Custom NGINX image based on `nginx:stable-alpine-otel`, built from [`nginx`](nginx), with:
- OpenTelemetry NGINX module enabled via [`nginx/config/nginx.conf`](nginx/config/nginx.conf)
- OpenTelemetry Collector (`otelcol-contrib`) installed and started by [`nginx/docker-entrypoint.sh`](nginx/docker-entrypoint.sh)
- Collector pipeline config from [`nginx/config/otel-config.yaml`](nginx/config/otel-config.yaml)

### Usage

```console
docker pull ghcr.io/matriphe/docker/nginx:otel
```

## PHP-FPM

Custom PHP-FPM image based on Debian trixie (`php:8.4-fpm-trixie`), built from [`php/fpm`](php/fpm) with:
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
- `ghcr.io/matriphe/docker/nginx:otel`
- `ghcr.io/matriphe/docker/php:8.4-fpm`
- `ghcr.io/matriphe/docker/wordpress:php8.4-fpm`
