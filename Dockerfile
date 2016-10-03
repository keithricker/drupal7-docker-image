# Standard Drupal 7 image

FROM drupal:7

# public key goes here
RUN if [ ! -d "/root/.ssh" ]; then mkdir /root/.ssh; fi
RUN chmod 0700 /root/.ssh

#Install Varnish
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -qy varnish

# Memcache Installation
RUN apt-get install -y php7.0-memcached
RUN memcached restart 2> /dev/null

# Install Apache Solr
RUN apt-get -y install openjdk-8-jdk
RUN mkdir /usr/java
RUN ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/java/default
RUN apt-get -y install solr-tomcat
# Solr configuration can be done by visiting: localhost:8080/solr
