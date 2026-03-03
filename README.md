# Docker

This is a collection of `Dockerfiles` to build custom images used by Muhammad Zamroi (matriphe).

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
