#!/bin/bash
set -a

echo "entering the start script ...."

source /host_app/config/scripts/drupal_config_variables.sh

# Copy shared files from server container to docker host machine for sharing
# Move anything newer from the container to the host, and delete anything in the existing config folder.
if [ ! -d "/host_app/config/drupal" ]; then
   if [ ! -d "/root/config" ]; then 
      echo "Container is not configured properly. Missing configuration directory."
      exit 0
   fi
fi

if [ ! -f "${SITEROOT}/index.php" ] && [ -f "${CODEBASEDIR}/index.php" ]; then
   rsync -a -u ${CODEBASEDIR}/ ${SITEROOT}/ || true
fi

bash /host_app/config/appserver/apache_start.sh
source /host_app/config/appserver/install_memcached.sh
