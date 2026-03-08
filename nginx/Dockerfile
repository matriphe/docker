FROM openresty/openresty:alpine

ARG USER=www-data

# Copy configuration files early to prevent them from invalidating build cache
COPY ./nginx/config/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf.template
COPY ./nginx/docker-entrypoint.sh /docker-entrypoint.sh

# Install runtime dependencies
# Cache mount preserves /var/cache/apk between builds for faster installs
RUN --mount=type=cache,target=/var/cache/apk \
    set -eux; \
    apk add --no-cache gettext

# Configure user and permissions
# Separate step for cacheability and clarity
RUN set -eux; \
    (addgroup -g 82 -S "${USER}" || true); \
    (adduser -u 82 -D -S -G "${USER}" "${USER}" || true); \
    mkdir -p /var/cache/nginx /var/log/nginx /etc/nginx/conf.d; \
    ln -sf /usr/local/openresty/nginx/conf/mime.types /etc/nginx/mime.types; \
    chown -R "${USER}:${USER}" /var/cache/nginx /var/log/nginx; \
    chmod -R 755 /var/cache/nginx /var/log/nginx; \
    chown "${USER}:${USER}" /docker-entrypoint.sh; \
    chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["openresty", "-g", "daemon off;"]
