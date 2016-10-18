#!/bin/bash

# Fix up the varnish config file because it doesn't seem to like variables.
if [ "${HOSTNAME}" != "" ]; then VARNISH_BACKEND_IP="${HOSTNAME}"; fi
sed -i -e “s/\${VARNISH_BACKEND_IP}/${varnishbeip}/g” /etc/varnish/default.vcl
sed -i -e “s/\${VARNISH_BACKEND_PORT}/${VARNISH_BACKEND_PORT}/g” /etc/varnish/default.vcl

service varnish start
