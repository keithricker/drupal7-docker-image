# Standard Drupal 7 image

FROM drupal:7

# public key goes here
RUN if [ ! -d "/root/.ssh" ]; then mkdir /root/.ssh; fi
RUN chmod 0700 /root/.ssh

#Install Varnish
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -qy varnish

# Memcache Installation
RUN apt-get install -y memcached
RUN apt-get install -y php-memcached memcache
RUN memcached restart 2> /dev/null
