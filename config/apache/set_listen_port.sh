#!/bin/bash

# Modify existing Apache2 configuration to give port 80 over to varnish
sed -i "s/Listen 80/Listen ${APACHE_LISTEN_PORT}/g" /etc/apache2/ports.conf
sed -i "s/VirtualHost \*:80/VirtualHost \*:${APACHE_LISTEN_PORT}/g" /etc/apache2/sites-available/default-ssl.conf
sed -i "s/VirtualHost \*:80/VirtualHost \*:${APACHE_LISTEN_PORT}/g" /etc/apache2/sites-available/000-default.conf

service apache2 reload
