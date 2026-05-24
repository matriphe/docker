#!/bin/sh

set -eu

REPO_ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"

cd "${REPO_ROOT}"

docker build -t matriphe/docker/nginx:openresty-local -f nginx/Dockerfile .

docker build \
  -t matriphe/docker/php:8.4-fpm-local \
  -t matriphe/docker/php:latest-local \
  --build-arg PHP_VERSION=8.4 \
  -f php/fpm/Dockerfile .

docker build \
  -t matriphe/docker/php:8.5-fpm-local \
  --build-arg PHP_VERSION=8.5 \
  -f php/fpm/Dockerfile .

docker build \
  -t matriphe/docker/wordpress:php8.4-fpm-local \
  -t matriphe/docker/wordpress:latest-local \
  --build-arg PHP_VERSION=8.4 \
  -f wordpress/Dockerfile .

docker build \
  -t matriphe/docker/wordpress:php8.5-fpm-local \
  --build-arg PHP_VERSION=8.5 \
  -f wordpress/Dockerfile .
