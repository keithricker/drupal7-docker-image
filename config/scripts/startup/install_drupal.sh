#!/bin/bash

# If we're establishing a connection and we have data, then we'll assume we're installed and we'll move along.
if drush pm-info node; then echo "Site is already installed here. Moving along." && continue; fi

echo "Attempting to import the database."

remotecommand = "ls -1rth ${EXTERNAL_DB_SITEROOT}/sites/default/files/private/backup_migrate/scheduled/*.mysql.gz | tail -1 ")"   
LATEST_FILE=$(ssh -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_IP} "${remotecommand}")
scp -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_IP}:${LATEST_FILE} ~/mysql-dump-file.sql

if drush sql-cli < ~/my-sql-dump-file.sql; then echo "Database import successful" && continue; else echo "Database import unseccessful"; fi

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
