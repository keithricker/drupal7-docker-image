#!/bin/bash
set -a

echo "entering the start script ...."

# Copy all environment variables from linked containers to main
"$(printenv)[@]"|while read line; do 
   modline=export $(sed "s/APPSERVER_//g" <<< $line) | xargs
   statement="export $modline"
   eval ${statement}
done

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
