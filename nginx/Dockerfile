FROM openresty/openresty:alpine

ARG USER=www-data

COPY ./nginx/config/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf.template
COPY ./nginx/docker-entrypoint.sh /docker-entrypoint.sh

RUN set -eux; \
    apk add --no-cache gettext; \
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
