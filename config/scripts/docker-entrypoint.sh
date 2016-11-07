#!/bin/bash
set -a

echo "entering the start script ...."

# Copy shared files from server container to docker host machine for sharing
# Move anything newer from the container to the host, and delete anything in the existing config folder.

if [ ! -d "/host_app/config/drupal" ]; then
    if [ ! -d "/root/config" ]; then 
        echo "Container is not configured properly. Missing configuration directory."
        exit 0
    fi
fi
if [ -d "/root/config" ]; then    
    rsync -a -u /root/config/ /host_app/config || true 
fi

rsync -a -u /var/www/codebase/ /host_app/code/ || true 

# Define a bunch of variables
drupalscripts=/host_app/config/scripts
source ${drupalscripts}/drupal_config_variables.sh

# If there is a private key defined in the env vars, then add it.
bash ${drupalscripts}/copy_private_key.sh



# create some directories and set permissions
bunchodirs=( ${DRUPAL_TMP_DIR} ${DRUPAL_FILES_DIR} ${DRUPAL_PRIVATE_DIR} )
for cooldir in "${bunchodirs[@]}";
do
if [ ! -d "$cooldir" ]
then
  mkdir -p $cooldir
  chmod 775 $cooldir
  chown -R www-data:www-data $cooldir
fi
done
chmod -R 664 ${DRUPAL_PRIVATE_DIR}

# Surrender ownership of the code
cd ${SITEROOT} && chown -R ${OWNERSHIP} ${SITEROOT} && chown -R www-data:www-data ${SITEROOT}

# Additional commands can be added by an environment variable
echo "Checking for additional command ... "
if [[ "$ADDITIONAL_COMMAND" != "" && "$ADDITIONAL_COMMAND" != "null" ]]
then
    echo "Running additional command ..."
    y=$(eval $ADDITIONAL_COMMAND)
    echo $y
fi

if [ -d "/root/config" ]; then
   rm -rf /root/config || true
   rm /usr/local/bin/docker-entrypoint && ln -s ${drupalscripts}/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
fi

# Start memcache
service memcached start || true

# Edit apache config files to listen on port specified in env variable, and start apache.
source /host_app/config/apache/apache/apache_start.sh
true
