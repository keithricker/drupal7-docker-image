#!/bin/bash
set -a

apt-get update && apt-get install -y memcached libmemcached-dev libmemcached11 git build-essential || true
export PHP_EXT_DIR /usr/src/php/ext
git clone -b php7 https://github.com/php-memcached-dev/php-memcached /usr/src/php/ext/memcached
docker-php-ext-install memcached || true
service start memcached || true
