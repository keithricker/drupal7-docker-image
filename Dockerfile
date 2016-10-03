# Standard Drupal 7 image

FROM drupal:7

# public key goes here
RUN if [ ! -d "/root/.ssh" ]; then mkdir /root/.ssh; fi
RUN chmod 0700 /root/.ssh

#Install Varnish
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -qy varnish

# Memcache Installation
RUN apt-get install -y libmemcached-dev libmemcached11 git build-essential
RUN git clone -b php7 https://github.com/php-memcached-dev/php-memcached
RUN cd php-memcached
RUN /usr/local/php7/bin/phpize
RUN ./configure --with-php-config=/usr/local/php7/bin/php-config
RUN make
RUN make install
RUN cd ../ && rm -r php-memcached
RUN memcached restart 2> /dev/null

# Install Apache Solr
RUN apt-get -y install openjdk-8-jdk
RUN mkdir /usr/java
RUN ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/java/default
RUN apt-get -y install solr-tomcat
# Solr configuration can be done by visiting: localhost:8080/solr
