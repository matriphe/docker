#!/bin/sh
# vim:sw=4:ts=4:et

# From original nginx docker-entrypoint.sh

set -e

entrypoint_log() {
    if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

if [ "$1" = "nginx" ] || [ "$1" = "nginx-debug" ] || [ "$1" = "openresty" ]; then
    if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
        entrypoint_log "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"

        entrypoint_log "$0: Looking for shell scripts in /docker-entrypoint.d/"
        find "/docker-entrypoint.d/" -follow -type f -print | sort -V | while read -r f; do
            case "$f" in
                *.envsh)
                    if [ -x "$f" ]; then
                        entrypoint_log "$0: Sourcing $f";
                        . "$f"
                    else
                        entrypoint_log "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *.sh)
                    if [ -x "$f" ]; then
                        entrypoint_log "$0: Launching $f";
                        "$f"
                    else
                        entrypoint_log "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *) entrypoint_log "$0: Ignoring $f";;
            esac
        done

        entrypoint_log "$0: Configuration complete; ready for start up"
    else
        entrypoint_log "$0: No files found in /docker-entrypoint.d/, skipping configuration"
    fi

    # Process Nginx configuration template
    entrypoint_log "$0: Generating nginx.conf from template..."
    envsubst < /usr/local/openresty/nginx/conf/nginx.conf.template > /usr/local/openresty/nginx/conf/nginx.conf

    # Start OpenTelemetry Collector sidecar if binary and config exist
    if [ -f "/usr/bin/otelcol-contrib" ] && [ -f "/etc/opentelemetry-collector/config.yaml" ]; then
        entrypoint_log "$0: Starting OpenTelemetry Collector..."
        /usr/bin/otelcol-contrib --config=/etc/opentelemetry-collector/config.yaml > /dev/stdout 2>&1 &
    fi
fi

# Run original NGINX command (usually: exec nginx -g 'daemon off;')
exec "$@"
