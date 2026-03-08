# Docker

This is a collection of `Dockerfiles` to build custom images used by Muhammad Zamroi (matriphe).

## OpenResty

Custom OpenResty image based on `openresty/openresty:alpine`, built from [`nginx`](nginx). OpenResty is Nginx with Lua scripting capabilities, providing enhanced flexibility and performance.

<!-- prettier-ignore -->
> [!IMPORTANT]
> **Legacy Image:** `nginx:otel` is now considered legacy and is no longer maintained. It has been replaced by `nginx:openresty`. All users should migrate to the new image for continued support and updates.

### Features

- Same configuration compatibility as Nginx
- Lua scripting support for custom logic
- Maintains all proxy and security settings from original Nginx config
- Built-in OpenTelemetry Collector sidecar for log collection and forwarding

### Pull OpenResty Image

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

### Pull PHP-FPM Image

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

### Pull WordPress Image

```console
docker pull ghcr.io/matriphe/docker/wordpress:php8.4-fpm
```

## CI / Publish Schedule

The GitHub Actions Docker publish workflow runs on Friday at `04:00 UTC` (`05:00/06:00 Europe/Berlin`, depending on DST) and publishes:

- `ghcr.io/matriphe/docker/nginx:openresty`
- `ghcr.io/matriphe/docker/php:8.4-fpm`
- `ghcr.io/matriphe/docker/wordpress:php8.4-fpm`

## Monitoring Setup with OpenTelemetry

### Production Setup with Sentry

1. Copy and configure environment variables:

```bash
cp .env.example .env
# Edit .env with your Sentry DSN and service name values
```

2. Create `docker-compose.yml` with Sentry integration:

```yaml
services:
  openresty:
    image: ghcr.io/matriphe/docker/nginx:openresty
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      php-fpm:
        condition: service_healthy

  php-fpm:
    image: ghcr.io/matriphe/docker/php:8.4-fpm
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=${OTEL_EXPORTER_OTLP_ENDPOINT}
      - OTEL_SERVICE_NAME=php-fpm
      - SENTRY_DSN=${SENTRY_DSN}
    healthcheck:
      test: ["CMD-SHELL", "nc -z localhost 9000 || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 5

  wordpress:
    image: ghcr.io/matriphe/docker/wordpress:php8.4-fpm
    environment:
      - WORDPRESS_DB_HOST=db
      - WORDPRESS_DB_USER=wordpress
      - WORDPRESS_DB_PASSWORD=wordpress
      - WORDPRESS_DB_NAME=wordpress
      - OTEL_EXPORTER_OTLP_ENDPOINT=${OTEL_EXPORTER_OTLP_ENDPOINT}
      - OTEL_SERVICE_NAME=wordpress
      - SENTRY_DSN=${SENTRY_DSN}
    depends_on:
      db:
        condition: service_healthy

  db:
    image: mariadb:10.11
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=wordpress
      - MYSQL_PASSWORD=wordpress
```

3. Start services:

```bash
docker compose up -d
```

### Development Setup with Jaeger

For testing OpenTelemetry traces locally without external dependencies:

1. Create `docker-compose.yml` with local Jaeger:

```yaml
services:
  openresty:
    image: ghcr.io/matriphe/docker/nginx:openresty
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      php-fpm:
        condition: service_healthy

  php-fpm:
    image: ghcr.io/matriphe/docker/php:8.4-fpm
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4317
      - OTEL_SERVICE_NAME=php-fpm
    healthcheck:
      test: ["CMD-SHELL", "nc -z localhost 9000 || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 5

  wordpress:
    image: ghcr.io/matriphe/docker/wordpress:php8.4-fpm
    environment:
      - WORDPRESS_DB_HOST=db
      - WORDPRESS_DB_USER=wordpress
      - WORDPRESS_DB_PASSWORD=wordpress
      - WORDPRESS_DB_NAME=wordpress
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4318
      - OTEL_SERVICE_NAME=wordpress
    depends_on:
      db:
        condition: service_healthy

  db:
    image: mariadb:10.11
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=wordpress
      - MYSQL_PASSWORD=wordpress

  jaeger:
    image: jaegertracing/jaeger:latest
    ports:
      - "16686:16686"
      - "4317:4317"
      - "4318:4318"
    volumes:
      - ./jaeger.yaml:/etc/jaeger/jaeger.yaml:ro
    command: ["--config", "/etc/jaeger/jaeger.yaml"]
```

2. Create a Jaeger v2 config file (`jaeger.yaml`):

Jaeger v2 requires a YAML configuration file. Use this minimal in-memory config for development:

```yaml
service:
  extensions: [jaeger_storage, jaeger_query]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [jaeger_storage_exporter]

extensions:
  jaeger_storage:
    backends:
      memstore:
        memory:
          max_traces: 10000
  jaeger_query:
    storage:
      traces: memstore

receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:

exporters:
  jaeger_storage_exporter:
    trace_storage: memstore
```

3. Start services and view Jaeger UI:

```bash
docker compose up -d
# Access Jaeger UI at http://localhost:16686
```

### OpenResty Log Collection (OTel Collector)

The OpenResty image includes a built-in OpenTelemetry Collector sidecar that automatically parses Nginx access and error logs and forwards them to OTLP-compatible backends (like Jaeger) and Sentry.

#### Configuring Sentry OTLP Logs

To send Nginx logs to Sentry using OTLP, configure these environment variables for the `openresty` service:

| Environment Variable | Description | Example |
|----------------------|-------------|---------|
| `SENTRY_OTLP_ENDPOINT` | The Sentry OTLP base URL (no path needed) | `https://oXXXXX.ingest.sentry.io` |
| `SENTRY_DSN_KEY` | The key part of your Sentry DSN | `abc123def456...` |
| `ENVIRONMENT` | Deployment environment name | `production`, `staging` |

**Example `docker-compose.yml` configuration:**

```yaml
services:
  openresty:
    image: ghcr.io/matriphe/docker/nginx:openresty
    ports:
      - "80:80"
    environment:
      - ENVIRONMENT=production
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4318
      - SENTRY_OTLP_ENDPOINT=https://oXXXXX.ingest.sentry.io
      - SENTRY_DSN_KEY=your-sentry-dsn-key
```

The collector automatically appends `/v1/logs` to the `SENTRY_OTLP_ENDPOINT`. Access logs are parsed as JSON and enriched with service information before export.

### Service-Specific Monitoring

#### PHP-FPM Monitoring

- **Service Name**: `php-fpm`
- **OTLP Endpoint**: `4317`
- **Configuration**: `config/php/php-instrumentation.ini`

#### WordPress Monitoring

- **Service Name**: `wordpress`
- **OTLP Endpoint**: `4318`
- **Configuration**: `config/wordpress/wp-instrumentation.ini`

### OTel Collector Receiver Port Configuration

The OTel Collector receiver ports can be customized via environment variables. This allows you to override default ports if needed for your deployment setup.

| Environment Variable           | Default Port | Purpose                                               |
| ------------------------------ | ------------ | ----------------------------------------------------- |
| `OTEL_RECEIVER_PORT_PHP`       | `4317`       | OTLP gRPC receiver port for PHP-FPM traces            |
| `OTEL_RECEIVER_PORT_WORDPRESS` | `4318`       | OTLP gRPC receiver port for WordPress traces          |
| `OTEL_RECEIVER_PORT_OPENRESTY` | `4319`       | OTLP gRPC receiver port for OpenResty traces (future) |

**Example:** Override PHP-FPM receiver port in `docker-compose.yml`:

```yaml
otel-collector:
  image: otel/opentelemetry-collector-contrib:latest
  environment:
    - OTEL_RECEIVER_PORT_PHP=14317
  ports:
    - "14317:14317"
```

The collector will bind to all interfaces (`0.0.0.0`) on the specified port. No environment variables are required—the collector uses defaults if not set.

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
docker compose logs php-fpm
docker compose logs wordpress
docker compose logs openresty
```

Verify OpenTelemetry extension is loaded:

```bash
docker compose exec php-fpm php -m | grep opentelemetry
docker compose exec wordpress php -m | grep opentelemetry
```

View OpenTelemetry traces in Jaeger (development only):

```bash
# Jaeger UI available at http://localhost:16686
# Select service from dropdown: php-fpm or wordpress
```
