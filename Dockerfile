# Standard Drupal 7 image

FROM drupal:7

WORKDIR /root

# Server's public html
ENV SITEROOT /var/www/html

# If user would like to create a new git branch from the contents of the public html directory,
# then specify the name of the new branch.
# ENV MAKE_GIT_BRANCH

# For passing in private key with environment variable
ENV PRIVATE_KEY_FILE root-aws-key.pem

# User can specify any additional commands to insert in the startup script
# ENV ADDITIONAL_COMMAND

# public key goes here
RUN if [ ! -d "/root/.ssh" ]; then mkdir /root/.ssh && chmod 0700 /root/.ssh; fi
RUN if [ ! -d "/root/.ssh_copy" ]; then mkdir /root/.ssh_copy && chmod 0700 /root/.ssh_copy; fi

# For sharing ssh key from host to container
VOLUME ["/root/.ssh_copy"]

#Install Varnish
RUN apt-get clean && apt-get update && apt-get upgrade -y
RUN apt-get install -qy varnish

# Varnish configuration variables
ENV VARNISH_BACKEND_PORT 8088
ENV VARNISH_BACKEND_IP 0.0.0.0
ENV VARNISH_PORT 80

# Varnish configuration
RUN $(echo find / -name "varnish" -ls)
# ADD config/varnish/default.vcl /etc/varnish/default.vcl

# Modify existing Apache2 configuration to give port 80 over to varnish
# RUN sed -i 's/Listen 80/Listen 8088/g' /etc/apache2/ports.conf
# RUN sed -i 's/VirtualHost \*:80/VirtualHost \*:8088/g' /etc/apache2/sites-available/www.conf
# RUN sed -i 's/VirtualHost \*:80/VirtualHost \*:8088/g' /etc/apache2/sites-available/000-default.conf
RUN $(echo ls /etc); exit 0

# Add configuration volumes for varnish
# VOLUME ["/var/lib/varnish"]
# VOLUME ["/etc/varnish"]

# Memcache Installation
RUN apt-get install -y memcached libmemcached-dev libmemcached11 git build-essential
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
RUN $(echo find / -name "solr" -ls)

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

# Add startup scripts
COPY config/kricker-d7-start.sh /root/kricker-d7-start.sh
COPY config/varnish/start.sh /root/varnish-start.sh
RUN chmod 777 /root/kricker-d7-start.sh
RUN chmod 777 /root/varnish-start.sh

WORKDIR /var/www/html

EXPOSE 8080 8088

CMD apache2-foreground && sh /root/kricker-d7-start.sh && sh /root/varnish-start.sh
