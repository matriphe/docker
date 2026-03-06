# Docker

This is a collection of `Dockerfiles` to build custom images used by Muhammad Zamroi (matriphe).

## OpenResty

Custom OpenResty image based on `openresty/openresty:alpine`, built from [`nginx`](nginx). OpenResty is Nginx with Lua scripting capabilities, providing enhanced flexibility and performance.

> [!IMPORTANT]
> **Legacy Image:** `nginx:otel` is now considered legacy and is no longer maintained. It has been replaced by `nginx:openresty`. All users should migrate to the new image for continued support and updates.

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
- PECL extensions: `apcu`, `excimer`, `opentelemetry`

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
- OpenTelemetry monitoring via [`config/wordpress/wp-instrumentation.ini`](config/wordpress/wp-instrumentation.ini)

### Usage

```console
docker pull ghcr.io/matriphe/docker/wordpress:php8.4-fpm
```

## CI / Publish Schedule

The GitHub Actions Docker publish workflow runs on Friday at `04:00 UTC` (`05:00/06:00 Europe/Berlin`, depending on DST) and publishes:
- `ghcr.io/matriphe/docker/nginx:openresty`
- `ghcr.io/matriphe/docker/php:8.4-fpm`
- `ghcr.io/matriphe/docker/wordpress:php8.4-fpm`


## Monitoring Setup with OpenTelemetry

### Production Setup

1. Copy and configure environment variables:
```bash
cp .env.example .env
# Edit .env with your Sentry DSN values
```

2. Start services with Docker Compose:
```bash
docker-compose up -d
```

### Development Setup with Jaeger

For testing without external dependencies:
```bash
docker-compose -f docker-compose.dev.yml up -d
# Access Jaeger UI at http://localhost:16686
```

### Service-Specific Monitoring

#### PHP-FPM Monitoring
- **Service Name**: `php-fpm`
- **OTLP Endpoint**: `4317`
- **Configuration**: `config/php/php-instrumentation.ini`

#### WordPress Monitoring  
- **Service Name**: `wordpress`
- **OTLP Endpoint**: `4318`
- **Configuration**: `config/wordpress/wp-instrumentation.ini`

### Performance Metrics

Each service captures:
- Request/response timing
- Database query performance  
- Memory usage
- Error rates and exceptions
- Service-specific metrics

### Troubleshooting

Check service health:
```bash
docker-compose logs php-fpm
docker-compose logs wordpress  
docker-compose logs otel-collector
```

Verify OpenTelemetry extension:
```bash
docker-compose exec php-fpm php -m | grep opentelemetry
docker-compose exec wordpress php -m | grep opentelemetry
```
