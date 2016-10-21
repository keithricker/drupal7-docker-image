#!/bin/bash

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
