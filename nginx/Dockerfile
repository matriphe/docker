FROM docker.io/library/nginx:stable-alpine-otel

ARG USER=www-data
ARG OTEL_VERSION=0.143.1
ARG TARGETOS=linux
ARG TARGETARCH

COPY ./nginx/config/nginx.conf /etc/nginx/nginx.conf.template
COPY ./nginx/config/otel-config.yaml /etc/opentelemetry-collector/config.yaml
COPY ./nginx/docker-entrypoint.sh /docker-entrypoint.sh

RUN set -eux; \
    apk add --no-cache curl ca-certificates tar gettext; \
    echo "Installing OpenTelemetry Collector version ${OTEL_VERSION} for ${TARGETOS}/${TARGETARCH}"; \
    if [ "${TARGETARCH}" = "amd64" ] || [ "${TARGETARCH}" = "x86_64" ]; then \
        ARCH="amd64"; \
    elif [ "${TARGETARCH}" = "arm64" ] || [ "${TARGETARCH}" = "aarch64" ]; then \
        ARCH="arm64"; \
    else \
        echo "Unsupported architecture: ${TARGETARCH}"; \
        exit 1; \
    fi && \
    curl -fsSL -o /tmp/otelcol.tar.gz "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_${TARGETOS}_${ARCH}.tar.gz"; \
    tar -xvf /tmp/otelcol.tar.gz -C /tmp otelcol-contrib; \
    chmod +x /tmp/otelcol-contrib; \
    mv /tmp/otelcol-contrib /usr/bin/otelcol-contrib; \
    rm -f /tmp/otelcol.tar.gz; \
    (addgroup -g 82 -S "${USER}" || true); \
    (adduser -u 82 -D -S -G "${USER}" "${USER}" || true); \
    chown -R "${USER}:${USER}" /var/cache/nginx /var/log/nginx; \
    chmod -R 755 /var/cache/nginx /var/log/nginx; \
    chown "${USER}:${USER}" /docker-entrypoint.sh; \
    chmod +x /docker-entrypoint.sh
