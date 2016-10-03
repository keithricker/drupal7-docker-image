# Standard Drupal 7 image

FROM drupal:7

# public key goes here
RUN if [ ! -d "/root/.ssh" ]; then mkdir /root/.ssh; fi
RUN chmod 0700 /root/.ssh

#Install Varnish & memcached
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -qy varnish

# Install Apache Solr
RUN apt-get -y install openjdk-8-jdk
RUN mkdir /usr/java
RUN ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/java/default
RUN apt-get -y install solr-tomcat
# Solr configuration can be done by visiting: localhost:8080/solr

# Memcache Installation
RUN apt-get install -y memcached
RUN apt-get install -y php-memcached
RUN memcached restart 2> /dev/null

# Varnish configuration
ADD config/varnish/default.vcl /etc/varnish/default.vcl
ENV VARNISH_BACKEND_PORT 8088
ENV VARNISH_BACKEND_IP 0.0.0.0
ENV VARNISH_PORT 80

# Server's public html
ENV SITEROOT /var/www/html

# If user would like to create a new git branch from the contents of the public html directory,
# then specify the name of the new branch.
ENV MAKE_GIT_BRANCH

# For passing in private key with environment variable
ENV PRIVATE_KEY_FILE root-aws-key.pem

# User can specify any additional commands to insert in the startup script
ENV ADDITIONAL_COMMAND

# Modify existing Apache2 configuration to give port 80 over to varnish
RUN sed -i 's/Listen 80/Listen 8088/g' /etc/apache2/ports.conf
RUN sed -i 's/VirtualHost \*:80/VirtualHost \*:8088/g' /etc/apache2/sites-available/www.conf
RUN sed -i 's/VirtualHost \*:80/VirtualHost \*:8088/g' /etc/apache2/sites-available/000-default.conf

COPY config/kricker-d7-start.sh ~/kricker-d7-start.sh
COPY config/varnish/start.sh ~/varnish-start.sh
RUN chmod 777 ~/kricker-d7-start.sh
RUN chmod 777 ~/varnish-start.sh

# Add configuration volumes for solr and varnish
VOLUME ["/usr/share/solr"]
VOLUME ["/var/lib/varnish"]
VOLUME ["/etc/varnish"]
# For sharing ssh key from host to container
VOLUME ["/root/.ssh"]

EXPOSE 8080 8088

CMD apache2-foreground && ~/kricker-d7-start.sh && ~/varnish-start.sh