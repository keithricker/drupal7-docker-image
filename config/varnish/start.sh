#!/bin/bash

if [ ! -z "$VARNISH_CONTENT_VCL" ]; then
	echo -e "$VARNISH_CONTENT_VCL" > /etc/varnish/default.vcl
	VARNISH_CONTENT="-f /etc/varnish/default.vcl"
fi

exec /usr/sbin/varnishd -a :$VARNISH_LISTEN_PORT $VARNISH_CONTENT -s $VARNISH_CACHE -S /etc/varnish/secret -F $VARNISH_OPTS

return;
