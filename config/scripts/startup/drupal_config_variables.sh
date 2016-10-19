#!/bin/bash

# Define a bunch of variables we will use for configuring our site installation. Database credentials and so forth.

drupalprofile=minimal
drupalsitename=drupal7
adminpass=drupal
dbname=drupal
dbhost=database
dbuname=drupal
dbpass=drupal
dbport=3306
# We'll over-ride the defaults if environment variables are defining them.
if [ "${DRUPAL_SITENAME}" != "" ]; then drupalsitename="${DRUPAL_SITENAME}"; fi
if [ "${MYSQL_ENV_MYSQL_DATABASE}" != "" ]; then dbname=$MYSQL_ENV_MYSQL_DATABASE; fi
if [ "${MYSQL_ENV_MYSQL_USER}" != "" ]; then dbuname=$MYSQL_ENV_MYSQL_USER; fi
if [ "${MYSQL_ENV_MYSQL_PASSWORD}" != "" ]; then dbpass=$MYSQL_ENV_MYSQL_PASSWORD; fi
if [ "${MYSQL_PORT_3306_TCP_PORT}" != "" ]; then dbport=$MYSQL_PORT_3306_TCP_PORT; fi

DRUPAL_SITE_DIR=${SITEROOT}/sites
DRUPAL_FILES_DIR=${SITEROOT}/sites/default/files
DRUPAL_PRIVATE_DIR=${SITEROOT}/sites/default/files/private
DRUPAL_TMP_DIR=${SITEROOT}/tmp
