FROM openresty/openresty:alpine

ARG USER=www-data

COPY ./nginx/config/nginx.conf /etc/nginx/nginx.conf.template
COPY ./nginx/docker-entrypoint.sh /docker-entrypoint.sh

RUN set -eux; \
    (addgroup -g 82 -S "${USER}" || true); \
    (adduser -u 82 -D -S -G "${USER}" "${USER}" || true); \
    mkdir -p /var/cache/nginx /var/log/nginx; \
    chown -R "${USER}:${USER}" /var/cache/nginx /var/log/nginx; \
    chmod -R 755 /var/cache/nginx /var/log/nginx; \
    chown "${USER}:${USER}" /docker-entrypoint.sh; \
    chmod +x /docker-entrypoint.sh