#!/bin/sh

set -eu

REPO_ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"

cd "${REPO_ROOT}"

docker build -t matriphe/docker/nginx:openresty-local -f nginx/Dockerfile .

docker build \
  -t matriphe/docker/php:8.5-fpm-local \
  -t matriphe/docker/php:latest-local \
  -f php/fpm/Dockerfile .

docker build \
  -t matriphe/docker/wordpress:php8.5-fpm-local \
  -t matriphe/docker/wordpress:latest-local \
  --build-arg PHP_VERSION=8.5 \
  -f wordpress/Dockerfile .
