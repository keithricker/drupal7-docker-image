# Minimal Busy Box inpsired container used to spin up a drupal project

FROM kalabox/cli:stable

WORKDIR /root

# Server's public html
ENV SITEROOT /var/www/html

# If git repo and/or branch are specified then we can use them for pulling/cloning codebase
ENV GIT_REPO https://github.com/drupal/drupal.git
ENV GIT_BRANCH 7.x
# If project is under version control and user would like to create a new git branch from their code base,
# then specify the name of the new branch to create.
# ENV MAKE_GIT_BRANCH

ENV IMPORT_EXTERNAL_DB false
ENV DB_IMPORT_METHOD ssh
# For passing in private key with environment variable
ENV PRIVATE_KEY_FILE root-aws-key.pem

# User can specify any additional commands to insert in the startup script
# ENV ADDITIONAL_COMMAND

# public key goes here
RUN if [ ! -d "/root/.ssh" ]; then mkdir /root/.ssh && chmod 0700 /root/.ssh; fi
RUN if [ ! -d "/root/.ssh_copy" ]; then mkdir /root/.ssh_copy && chmod 0700 /root/.ssh_copy; fi

# For sharing ssh key from host to container
VOLUME ["/root/.ssh_copy"]

#For sharing config files between host and container
COPY config /root/config
RUN mkdir -p /host_app/config && chmod -R 777 /root/config /host_app

# Here you can set the port that Apache serves from (listens on) 
ENV APACHE_LISTEN_PORT 80

# Memcache Installation
#
# RUN apt-get update && apt-get install -y memcached libmemcached-dev libmemcached11 git build-essential || true
# ENV PHP_EXT_DIR /usr/src/php/ext
# RUN git clone -b php7 https://github.com/php-memcached-dev/php-memcached /usr/src/php/ext/memcached &&\
#    docker-php-ext-install memcached
#

# Install composer
#
# WORKDIR /root
# RUN curl -sS https://getcomposer.org/installer | php
# RUN mv /root/composer.phar /usr/local/bin/composer
# WORKDIR /root/.composer
# RUN composer global update

# Archive contents of the web root and stash it for later
RUN mkdir -p /var/www/codebase
ENV CODEBASEDIR /var/www/codebase

ENTRYPOINT bash
RUN ln -s /root/config/scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
CMD ["docker-entrypoint"]
