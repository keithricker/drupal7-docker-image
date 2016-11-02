#!/bin/bash
set -a
# Define a bunch of variables we will use for configuring our site installation. Database credentials and so forth.

drupalprofile=${DRUPAL_PROFILE:-minimal}
drupalsitename=${HOSTNAME:-drupal7}
drupalsitename=${DRUPAL_SITENAME:-$drupalsitename}

# If framework variable is set then we'll use this for just about everything.
FRAMEWORK=${FRAMEWORK:-drupal}
adminpass=${FRAMEWORK}
dbname=${MYSQL_ENV_MYSQL_DATABASE:-$FRAMEWORK}

dbhost=${DB_LINK:-database}
# dbhost=${MYSQL_PORT_3306_TCP_ADDR:-database}
dbuname=${MYSQL_ENV_MYSQL_USER:-$FRAMEWORK}
dbpass=${MYSQL_ENV_MYSQL_PASSWORD:-$FRAMEWORK}
dbport=${MYSQL_PORT_3306_TCP_PORT:-3306}

DRUPAL_SITE_DIR=${SITEROOT}/sites
DRUPAL_FILES_DIR=${SITEROOT}/sites/default/files
DRUPAL_PRIVATE_DIR=${SITEROOT}/sites/default/files/private
DRUPAL_TMP_DIR=${SITEROOT}/tmp
