FROM openresty/openresty:alpine

ARG USER=www-data

LABEL maintainer="Muhammad Zamroni <halo@matriphe.com>"

# Copy configuration files early (rarely change, maximizes cache hits)
COPY ./nginx/config/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf.template
COPY ./nginx/config/otel-config.yaml /etc/opentelemetry-collector/config.yaml
COPY ./nginx/docker-entrypoint.sh /docker-entrypoint.sh

# Install runtime dependencies (stable layer, rarely changes)
RUN --mount=type=cache,target=/var/cache/apk \
    set -eux; \
    apk add --no-cache gettext curl ca-certificates tar

# Configure user and permissions (stable layer)
RUN set -eux; \
    (addgroup -g 82 -S "${USER}" || true); \
    (adduser -u 82 -D -S -G "${USER}" "${USER}" || true); \
    mkdir -p /var/cache/nginx /var/log/nginx /etc/nginx/conf.d; \
    ln -sf /usr/local/openresty/nginx/conf/mime.types /etc/nginx/mime.types; \
    chown -R "${USER}:${USER}" /var/cache/nginx /var/log/nginx; \
    chmod -R 755 /var/cache/nginx /var/log/nginx; \
    chown "${USER}:${USER}" /docker-entrypoint.sh; \
    chmod +x /docker-entrypoint.sh

# Install OTel Collector LAST — version bumps only invalidate this layer
ARG OTEL_VERSION=0.143.1
ARG TARGETOS=linux
ARG TARGETARCH

RUN set -eux; \
    if [ "${TARGETARCH}" = "amd64" ] || [ "${TARGETARCH}" = "x86_64" ]; then ARCH="amd64"; \
    elif [ "${TARGETARCH}" = "arm64" ] || [ "${TARGETARCH}" = "aarch64" ]; then ARCH="arm64"; \
    else echo "Unsupported architecture: ${TARGETARCH}"; exit 1; fi; \
    curl -L -o otelcol.tar.gz "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_${TARGETOS}_${ARCH}.tar.gz"; \
    tar -xvf otelcol.tar.gz otelcol-contrib; \
    chmod +x otelcol-contrib; \
    mv otelcol-contrib /usr/bin/otelcol-contrib; \
    rm otelcol.tar.gz

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["openresty", "-g", "daemon off;"]
