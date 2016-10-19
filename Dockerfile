# Standard Drupal 7 image

FROM drupal:7

WORKDIR /root

# Server's public html
ENV SITEROOT /var/www/html

# If git repo and/or branch are specified then we can use them for pulling/cloning codebase
# ENV GIT_REPO
ENV GIT_BRANCH master
# If project is under version control and user would like to create a new git branch from their code base,
# then specify the name of the new branch to create.
# ENV MAKE_GIT_BRANCH

# Source for downloading fresh drupal sourcecode - this will be used by default.
ENV DRUPAL_SOURCE https://github.com/drupal/drupal.git
ENV DRUPAL_VERSION 7.x

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
RUN mkdir -p /root/host_app/config && chmod -R 777 /root/config /root/host_app
VOLUME ["/root/host_app/config"]

# Here you can set the port that Apache serves from (listens on) 
ENV APACHE_LISTEN_PORT 80

# Memcache Installation
RUN apt-get update && apt-get install -y memcached libmemcached-dev libmemcached11 git build-essential || true
ENV PHP_EXT_DIR /usr/src/php/ext
RUN git clone -b php7 https://github.com/php-memcached-dev/php-memcached /usr/src/php/ext/memcached &&\
    docker-php-ext-install memcached

# Install Apache Solr
RUN apt-get -y install openjdk-7-jre 
RUN apt-get -y install openjdk-7-jdk
RUN mkdir /usr/java
RUN ln -s /usr/lib/jvm/java-7-openjdk-amd64 /usr/java/default
RUN apt-get -y install solr-tomcat
# Solr configuration can be done by visiting: localhost:8080/solr
# Add configuration volume for solr
# VOLUME ["/usr/share/solr"]

# Install composer
WORKDIR /root
RUN curl -sS https://getcomposer.org/installer | php
RUN mv /root/composer.phar /usr/local/bin/composer

# Install Drush 7.
WORKDIR /root/.composer
RUN composer global require drush/drush:7.*
RUN composer global update
WORKDIR /root
RUN ln -s /root/.composer/vendor/bin/drush /usr/bin

# Archive contents of the web root and stash it for later
WORKDIR /var/www
RUN mkdir codebase && tar -zcf codebase/codebase.tar.gz html
WORKDIR /var/www/html

EXPOSE 8080 8088

CMD apache2-foreground && bash /root/config/drupal-start.sh
