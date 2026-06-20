#!/bin/sh

set -eu

: "${NGINX_IMAGE:?NGINX_IMAGE is required}"
: "${PHP_IMAGE:?PHP_IMAGE is required}"
: "${WORDPRESS_IMAGE:?WORDPRESS_IMAGE is required}"
: "${EXPECTED_PHP_VERSION:?EXPECTED_PHP_VERSION is required}"

TEST_ENV_DIR="${TEST_ENV_DIR:-.test-env}"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-image-test-${EXPECTED_PHP_VERSION%.*}${EXPECTED_PHP_VERSION#*.}}"
APP_PORT="${APP_PORT:-8080}"
JAEGER_UI_PORT="${JAEGER_UI_PORT:-16686}"
OTLP_GRPC_PORT="${OTLP_GRPC_PORT:-4317}"
OTLP_HTTP_PORT="${OTLP_HTTP_PORT:-4318}"
SENTRY_MOCK_PORT="${SENTRY_MOCK_PORT:-9099}"

cleanup() {
  if [ -d "${TEST_ENV_DIR}" ]; then
    docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" down -v >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

mkdir -p "${TEST_ENV_DIR}"

cat <<EOF > "${TEST_ENV_DIR}/docker-compose.yml"
volumes:
  wp_data:
  php_data:

services:
  openresty:
    image: ${NGINX_IMAGE}
    ports:
      - "${APP_PORT}:80"
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4318
      - SENTRY_OTLP_ENDPOINT=http://sentry-mock:8080
      - SENTRY_DSN_KEY=test-sentry-key
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - wp_data:/var/www/wordpress:ro
      - php_data:/var/www/php:ro
    depends_on:
      php-fpm:
        condition: service_healthy
      wordpress:
        condition: service_healthy
      sentry-mock:
        condition: service_healthy
  php-fpm:
    image: ${PHP_IMAGE}
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4318
      - OTEL_SERVICE_NAME=php-fpm
      - PHP_INI_MEMORY__LIMIT=256M
    volumes:
      - php_data:/var/www/php:rw
    depends_on:
      jaeger:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "nc -z localhost 9000 || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 5
  wordpress:
    user: root
    image: ${WORDPRESS_IMAGE}
    environment:
      - WORDPRESS_DB_HOST=db
      - WORDPRESS_DB_USER=wordpress
      - WORDPRESS_DB_PASSWORD=wordpress
      - WORDPRESS_DB_NAME=wordpress
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4318
      - OTEL_SERVICE_NAME=wordpress
    volumes:
      - wp_data:/var/www/wordpress:rw
    depends_on:
      db:
        condition: service_healthy
      jaeger:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "nc -z localhost 9000 || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 5
  db:
    image: mariadb:10.11
    environment:
      - MARIADB_DATABASE=wordpress
      - MARIADB_USER=wordpress
      - MARIADB_PASSWORD=wordpress
      - MARIADB_ROOT_PASSWORD=wordpress
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 5s
      timeout: 5s
      retries: 5
  jaeger:
    image: jaegertracing/jaeger:latest
    ports:
      - "${JAEGER_UI_PORT}:16686"
      - "${OTLP_GRPC_PORT}:4317"
      - "${OTLP_HTTP_PORT}:4318"
    volumes:
      - ./jaeger.yaml:/etc/jaeger/jaeger.yaml:ro
    command: ["--config", "/etc/jaeger/jaeger.yaml"]
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://localhost:14133/ || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 10
  sentry-mock:
    image: wiremock/wiremock:latest
    ports:
      - "${SENTRY_MOCK_PORT}:8080"
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://localhost:8080/__admin/health || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 10
EOF

cat <<'EOF' > "${TEST_ENV_DIR}/nginx.conf"
server {
    listen 80;
    server_name localhost;
    index index.php index.html;

    location /info.php {
        root /var/www/php;
        fastcgi_pass php-fpm:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location / {
        root /var/www/wordpress;
        try_files $uri $uri/ /index.php?$args;

        location ~ \.php$ {
            fastcgi_pass wordpress:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
}
EOF

cat <<'EOF' > "${TEST_ENV_DIR}/jaeger.yaml"
extensions:
  healthcheckv2:
    endpoint: 0.0.0.0:14133
  jaeger_query:
    storage:
      traces: memstore
  jaeger_storage:
    backends:
      memstore:
        memory:
          max_traces: 10000

receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

exporters:
  jaeger_storage_exporter:
    trace_storage: memstore
  debug:
    verbosity: detailed

processors:
  batch:

service:
  extensions: [healthcheckv2, jaeger_query, jaeger_storage]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [jaeger_storage_exporter]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
EOF

docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" up -d --wait
docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" ps

docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -u root -T php-fpm sh -c \
  "mkdir -p /var/www/php && echo '<?php echo phpversion(); ?>' > /var/www/php/info.php"
docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -u root -T php-fpm \
  chown www-data:www-data /var/www/php/info.php

curl -sf -X POST "http://localhost:${SENTRY_MOCK_PORT}/__admin/mappings" \
  -H "Content-Type: application/json" \
  -d '{
    "request": {
      "method": "POST",
      "urlPathPattern": "/.*"
    },
    "response": {
      "status": 200,
      "body": "{\"partialSuccess\":{}}",
      "headers": {
        "Content-Type": "application/json"
      }
    }
  }' >/dev/null

docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T openresty openresty -t
curl -sI "http://localhost:${APP_PORT}/info.php" >/dev/null
curl -s "http://localhost:${APP_PORT}/info.php" | grep "^${EXPECTED_PHP_VERSION}"

ACTUAL_PHP_VERSION="$(docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T php-fpm php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
if [ "${ACTUAL_PHP_VERSION}" != "${EXPECTED_PHP_VERSION}" ]; then
  echo "php-fpm version mismatch: expected ${EXPECTED_PHP_VERSION}, got ${ACTUAL_PHP_VERSION}" >&2
  exit 1
fi

ACTUAL_WP_VERSION="$(docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T wordpress php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
if [ "${ACTUAL_WP_VERSION}" != "${EXPECTED_PHP_VERSION}" ]; then
  echo "wordpress version mismatch: expected ${EXPECTED_PHP_VERSION}, got ${ACTUAL_WP_VERSION}" >&2
  exit 1
fi

docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T php-fpm php -m

docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T wordpress \
  rm -f /var/www/wordpress/wp-config.php || true
docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T wordpress \
  wp core config --dbhost=db --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --allow-root
docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T wordpress \
  wp core install --url="http://localhost:${APP_PORT}" --title="Test Site" --admin_user="admin" \
  --admin_password="password" --admin_email="admin@example.com" --allow-root
docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T wordpress \
  wp plugin list --allow-root
curl -s "http://localhost:${APP_PORT}/" | grep -i "Test Site"

docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T php-fpm php -m | grep -q opentelemetry
docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T wordpress php -m | grep -q opentelemetry
docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T php-fpm \
  cat /usr/local/etc/php/conf.d/opentelemetry.ini | grep -q "opentelemetry.enabled = On"
docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T php-fpm \
  cat /usr/local/etc/php/conf.d/opentelemetry.ini | grep -q "opentelemetry.traces_exporter = otlp_http"

echo "=== Testing PHP_INI_* env var override ==="
ACTUAL_MEMORY_LIMIT="$(docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T php-fpm php -r 'echo ini_get("memory_limit");')"
if [ "${ACTUAL_MEMORY_LIMIT}" != "256M" ]; then
  echo "PHP_INI_MEMORY__LIMIT test failed: expected 256M, got ${ACTUAL_MEMORY_LIMIT}" >&2
  exit 1
fi
echo "PHP_INI_MEMORY__LIMIT test passed: ${ACTUAL_MEMORY_LIMIT}"

for _ in $(seq 1 10); do
  curl -sf "http://localhost:${APP_PORT}/" >/dev/null || true
  curl -sf "http://localhost:${APP_PORT}/info.php" >/dev/null || true
done

sleep 10

OTEL_PID="$(docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T openresty pgrep otelcol-contrib 2>/dev/null || true)"
if [ -z "${OTEL_PID}" ]; then
  echo "otelcol-contrib is not running" >&2
  docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" logs openresty
  exit 1
fi

if docker compose -p "${COMPOSE_PROJECT_NAME}" -f "${TEST_ENV_DIR}/docker-compose.yml" exec -T openresty \
  cat /var/log/nginx/otelcol.log 2>/dev/null | grep -qi "failed to export\|export.*failed"; then
  echo "OTel collector reported export failures" >&2
  exit 1
fi

curl -sf "http://localhost:${JAEGER_UI_PORT}/api/services" >/dev/null

SENTRY_COUNT="$(curl -sf -X POST "http://localhost:${SENTRY_MOCK_PORT}/__admin/requests/count" \
  -H "Content-Type: application/json" \
  -d '{"method":"POST","urlPathPattern":"/.*"}' | grep -o '"count":[0-9]*' | grep -o '[0-9]*' || echo "0")"

if [ -z "${SENTRY_COUNT}" ]; then
  echo "Unable to determine Sentry mock request count" >&2
  exit 1
fi

echo "Validated PHP ${EXPECTED_PHP_VERSION} with ${SENTRY_COUNT} Sentry mock request(s)."
