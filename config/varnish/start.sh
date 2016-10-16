#!/bin/bash

# Fix up the varnish config file because it doesn't seem to like variables.
if [ "${HOSTNAME}" != "" ]; then VARNISH_BACKEND_IP="${HOSTNAME}"; fi
sed -i -e “s/\${VARNISH_BACKEND_IP}/${varnishbeip}/g” /etc/varnish/default.vcl
sed -i -e “s/\${VARNISH_BACKEND_PORT}/${VARNISH_BACKEND_PORT}/g” /etc/varnish/default.vcl

if [ ! -z "$VARNISH_CONTENT_VCL" ]; then
    echo -e "$VARNISH_CONTENT_VCL" > /etc/varnish/default.vcl
    VARNISH_CONTENT="-f /etc/varnish/default.vcl"
fi

exec /usr/sbin/varnishd -a :$VARNISH_LISTEN_PORT $VARNISH_CONTENT -s $VARNISH_CACHE -S /etc/varnish/secret -F $VARNISH_OPTS
