# Standard Drupal 7 image

FROM drupal:7

WORKDIR /root

# Varnish configuration variables
ENV VARNISH_BACKEND_PORT 8088
ENV VARNISH_BACKEND_IP 0.0.0.0
ENV VARNISH_PORT 80

# Server's public html
ENV SITEROOT /var/www/html

# public key goes here
RUN if [ ! -d "/root/.ssh" ]; then mkdir /root/.ssh; fi
RUN chmod 0700 /root/.ssh

#Install Varnish
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -qy varnish

# Varnish configuration
ADD config/varnish/default.vcl /etc/varnish/default.vcl

# Memcache Installation
RUN apt-get install -y libmemcached-dev libmemcached11 git build-essential
RUN git clone -b php7 https://github.com/php-memcached-dev/php-memcached
WORKDIR /root/php-memcached
RUN phpize
RUN ./configure --with-php-config=/usr/local/bin/php-config
RUN make
RUN make install
WORKDIR /root
RUN rm -r php-memcached

# Install Apache Solr
RUN apt-get -y install openjdk-7-jre 
RUN apt-get -y install openjdk-7-jdk
RUN mkdir /usr/java
RUN ln -s /usr/lib/jvm/java-7-openjdk-amd64 /usr/java/default
RUN apt-get -y install solr-tomcat
# Solr configuration can be done by visiting: localhost:8080/solr
