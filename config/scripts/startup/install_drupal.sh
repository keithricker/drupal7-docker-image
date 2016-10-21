#!/bin/bash

# If we're establishing a connection and we have data, then we'll assume we're installed and we'll move along.
if drush pm-info node; then echo "Site is already installed here. Moving along." && continue; fi

# If we're importing an external database, then we'll attempt to connect to the external server and grab it.
if [ "${IMPORT_EXTERNAL_DB}" ]
then
   echo "Attempting to import the database."
   remotecommand="cd ${EXTERNAL_DB_WEBROOT}/sites/${dir} && "
   remotecommand+="drush cc all && drush sql-dump -y > ~/my-sql-dump-file.sql"
   ssh -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_IP} "${remotecommand}"
   scp -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_IP}:~/my-sql-dump-file.sql /root
fi

if [ -f "${DRUPAL_SETTINGS}" ]; then mv ${DRUPAL_SETTINGS} ${DRUPAL_SETTINGS}.bak; fi

if [ "$dir" != "default" ]
then
  drush sql-create --db-url=mysql://$dbuname:$dbpass@$dbhost:$dbport/$dbname --yes || true
fi

if ! drush site-install standard --site-name=${drupalsitename} --account-pass=$adminpass --db-url=mysql://$dbuname:$dbpass@$dbhost:$dbport/$dbname --yes
then
  echo "Unable to configure your Drupal installation at $DRUPAL_SITE_DIR/$dir"
  echo
  continue
fi
