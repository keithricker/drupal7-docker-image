#!/bin/bash

# See if we have any config files to move over
if [ -f "/root-config/varnish" ]
then
   mv -u /root/config/varnish /root/host_app/config || true
   rm /etc/varnish/default.vcl || true
   ln -s /root/host_app/config/varnish/default.vcl /etc/varnish/default.vcl  || true
fi

# Fix up the varnish config file because it doesn't seem to like variables.
if [ "${HOSTNAME}" != "" ]; then VARNISH_BACKEND_IP="${HOSTNAME}"; fi
sed -i -e “s/\${VARNISH_BACKEND_IP}/${varnishbeip}/g” /root/host_app/config/varnish/default.vcl
sed -i -e “s/\${VARNISH_BACKEND_PORT}/${VARNISH_BACKEND_PORT}/g” /root/host_app/config/varnish/default.vcl

service varnish start
