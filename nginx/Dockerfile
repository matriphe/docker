# Base image
FROM nginx:stable-alpine-otel

# Create www-data user and group
ARG USER=www-data

# Check for latest OpenTelemetry version from https://github.com/open-telemetry/opentelemetry-collector-releases
# Last checked: 2026-01-11
ARG OTEL_VERSION=0.143.1

# Target platform (OS and architecture) for installing OpenTelemetry Collector
ARG TARGETOS=linux
ARG TARGETARCH

# Copy optimized Nginx and OpenTelemetry Collector configuration
COPY ./config/nginx.conf /etc/nginx/nginx.conf.template
COPY ./config/otel-config.yaml /etc/opentelemetry-collector/config.yaml

# Copy custom entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN \
    # Install runtime dependencies
    apk update && \
    apk add --no-cache curl ca-certificates tar gettext && \
    \
    # Install OpenTelemetry Collector based on target architecture
    echo "Installing OpenTelemetry Collector version ${OTEL_VERSION} for ${TARGETOS}/${TARGETARCH}" && \
    if [ "${TARGETARCH}" = "amd64" ] || [ "${TARGETARCH}" = "x86_64" ]; then \
    ARCH="amd64"; \
    elif [ "${TARGETARCH}" = "arm64" ] || [ "${TARGETARCH}" = "aarch64" ]; then \
    ARCH="arm64"; \
    else \
    echo "Unsupported architecture: ${TARGETARCH}"; \
    exit 1; \
    fi && \
    curl -L -o otelcol.tar.gz "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_${TARGETOS}_${ARCH}.tar.gz" && \
    tar -xvf otelcol.tar.gz otelcol-contrib && \
    chmod +x otelcol-contrib && \
    mv otelcol-contrib /usr/bin/otelcol-contrib && \
    rm otelcol.tar.gz && \
    \
    # Create www-data user and group (required by nginx.conf)
    # Using UID/GID 82 which is the standard for www-data in Alpine Linux
    # This ensures consistency across systems and proper file ownership
    # Note: Using "|| true" pattern to handle cases where www-data already exists in base image
    # This prevents build failures while ensuring the user/group exists with correct UID/GID
    (addgroup -g 82 -S ${USER} || true) && \
    (adduser -u 82 -D -S -G ${USER} ${USER} || true) && \
    \
    # Ensure proper permissions for nginx directories
    chown -R ${USER}:${USER} /var/cache/nginx && \
    chown -R ${USER}:${USER} /var/log/nginx && \
    chmod -R 755 /var/cache/nginx && \
    chmod -R 755 /var/log/nginx && \
    \
    # Ensure entrypoint script is executable
    chown ${USER}:${USER} /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh && \
    \
    # Cleanup apk cache
    rm -rf /var/cache/apk/*
