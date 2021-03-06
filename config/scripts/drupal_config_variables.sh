#!/bin/bash
set -a

# Copy all environment variables from linked containers to main
function env_mangle {
"$(printenv)[@]"|while read line; do
if [[ $line == *"RUNNER_"* ]]; then
   modline=$(sed "s/RUNNER_ENV_//g" <<< $line | xargs)
   modline=$(sed "s/RUNNER_//g" <<< $modline | xargs)
   modline=$(sed "s/APPSERVER_ENV_//g" <<< $modline | xargs)
   modline=$(sed "s/APPSERVER_//g" <<< $modline | xargs)   
   statement="export $modline"
   eval ${statement} || true
fi
done
}

env_mangle || true

# Define a bunch of variables we will use for configuring our site installation. Database credentials and so forth.
ROOT_USER_ID=${ROOT_USER_ID:-"1"}
ROOT_GROUP_ID=${ROOT_GROUP_ID:-"0"}
if [ "$OWNERSHIP" == "" ]; then OWNERSHIP="${ROOT_USER_ID}:${ROOT_GROUP_ID}"; fi

hostconfig=/host_app/config
drupalscripts=/host_app/config/scripts
drushscripts=/host_app/config/drush-site-install

drupalprofile=${DRUPAL_PROFILE:-minimal}
drupalsitename=${HOSTNAME:-drupal7}
drupalsitename=${DRUPAL_SITENAME:-$drupalsitename}

# If framework variable is set then we'll use this for just about everything.
FRAMEWORK=${FRAMEWORK:-drupal}
adminpass=${FRAMEWORK}
dbname=${MYSQL_ENV_MYSQL_DATABASE:-$FRAMEWORK}

dbhost=${MYSQL_HOST:-database}
# dbhost=${MYSQL_PORT_3306_TCP_ADDR:-database}
dbuname=${MYSQL_ENV_MYSQL_USER:-$FRAMEWORK}
dbpass=${MYSQL_ENV_MYSQL_PASSWORD:-$FRAMEWORK}
dbport=${MYSQL_PORT_3306_TCP_PORT:-3306}

DRUPAL_SITE_DIR=${SITEROOT}/sites
DRUPAL_FILES_DIR=${SITEROOT}/sites/default/files
DRUPAL_PRIVATE_DIR=${SITEROOT}/sites/default/files/private
DRUPAL_TMP_DIR=${SITEROOT}/tmp
