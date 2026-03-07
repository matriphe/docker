FROM docker.io/library/nginx:stable-alpine-otel

ARG USER=www-data
ARG OTEL_VERSION=0.143.1
ARG TARGETOS=linux
ARG TARGETARCH

# Copy configuration files early to prevent them from invalidating the OpenTelemetry binary cache
COPY ./nginx/config/nginx.conf /etc/nginx/nginx.conf.template
COPY ./nginx/config/otel-config.yaml /etc/opentelemetry-collector/config.yaml
COPY ./nginx/docker-entrypoint.sh /docker-entrypoint.sh

# Install runtime dependencies
# Cache mount preserves /var/cache/apk between builds for faster installs
RUN --mount=type=cache,target=/var/cache/apk \
    set -eux; \
    apk add --no-cache curl ca-certificates tar gettext

# Download and install OpenTelemetry Collector binary
# Separate step allows caching of architecture-specific binary downloads
# Cache mount preserves /tmp between builds to avoid re-downloading on retry
RUN --mount=type=cache,target=/tmp \
    set -eux; \
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
    rm -f /tmp/otelcol.tar.gz

# Configure user and permissions
# Separate step for cacheability and clarity
RUN set -eux; \
    (addgroup -g 82 -S "${USER}" || true); \
    (adduser -u 82 -D -S -G "${USER}" "${USER}" || true); \
    chown -R "${USER}:${USER}" /var/cache/nginx /var/log/nginx; \
    chmod -R 755 /var/cache/nginx /var/log/nginx; \
    chown "${USER}:${USER}" /docker-entrypoint.sh; \
    chmod +x /docker-entrypoint.sh
