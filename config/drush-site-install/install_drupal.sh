#!/bin/bash
set -a

# Getting ready to install drupal. 
# First need to include our variables
drupalscripts=/host_app/config/scripts
source ${drupalscripts}/drupal_config_variables.sh

for dir in ${DRUPAL_SITE_DIR}/*/;
do
export DIR=$dir
# get the name of the current directory and assign it to dir
dir=${dir%*/}
dir=${dir##*/}
DRUPAL_DEFAULT_SETTINGS=${DRUPAL_SITE_DIR}/$dir/default.settings.php
DRUPAL_SETTINGS=${DRUPAL_SITE_DIR}/$dir/settings.php
DRUPAL_LOCAL_SETTINGS=${DRUPAL_SITE_DIR}/$dir/local.settings.php
DRUPAL_LOCAL_SETTINGS_ORIGIN=${drupalscripts}/../appserver/local.settings.php

echo "Checking for existing site configuration ... "
# break out if site is configured already or we're in sites/all
if [ "$dir" == "all" ]; then continue; fi;

if [ -f "${DRUPAL_SITE_DIR}/$dir/local.settings.php" ]
then
  echo "Drupal is already configured in ${DRUPAL_SITE_DIR}/$dir. Delete local.settings.php to rerun setup"
  continue
fi
if [ "${dir}" != "default" ]
then
   var=$dir
   nodot=${var//.}
   nouscore=${nodot//_}
   dbname=$nouscore
   drupalsitename="$drupalsitename-${dbname}"
else
   source ${drupalscripts}/drupal_config_variables.sh
fi

export MYSQL_URL="mysql://$dbuname:$dbpass@$dbhost:$dbport/$dbname"
export MYSQL_ROOT_CREDS="--db-su=$dbuname --db-su-pw=$dbpass"

# If we're establishing a connection and we have data, then we'll assume we're installed and we'll move along.
cd ${DRUPAL_SITE_DIR}/$dir
if drush pm-info node --fields=status; then echo "Site is already installed here. Moving along." && continue; else true; fi

# Install the site
#
echo ""
echo "Creating a new Drupal site at ${DRUPAL_SITE_DIR}/$dir"
echo ""

if [ ! -f "${DRUPAL_SETTINGS}" ]; then 
    cp -rp ../default/default.settings.php settings.php
fi

includestring="\$localsettings = \$drupalenv.'.settings.php"
if ! grep "$includestring" ${DRUPAL_SETTINGS};
then
   source ${drushscripts}/modify_settings_file_1.sh
fi

cp ${DRUPAL_LOCAL_SETTINGS_ORIGIN} && chown www-data:www-data local.settings.php
if [ "$dir" != "default" ];
then
    # Just replacing the environment variable for the database name with the name of the new database we're creating.
    revisedsettings=$(sed "s/\$src\['MYSQL_ENV_MYSQL_DATABASE']/'${dbname}'/"<<<"$(cat local.settings.php)")
    echo "$revisedsettings" > local.settings.php
fi

echo "Attempting to install the database."

if [ -z $first_site_installed ]; 
then
   if ! drush site-install minimal --site-name=${drupalsitename} --account-pass=$adminpass ${MYSQL_ROOT_CREDS} --sites-subdir=$dir --db-url=${MYSQL_URL} -y
   then
      echo "Unable to configure your Drupal installation at $DRUPAL_SITE_DIR/$dir"
      echo "" && true
   else
      echo "Site successfully installed in sites/$dir"
      first_site_installed=$dir
   fi
else
   cd ../$first_site_installed && drush sql-dump --result-file=mysqldump.sql
   drush sql-create --db-url=${MYSQL_URL} -y
   cd ../$dir && drush cc drush || true
   drush sql-cli --db-url=${MYSQL_URL} < ../$first_site_installed/mysqldump.sql -y
fi


# If we're importing an external database, then we'll attempt to connect to the external server and grab it.
if [ "${IMPORT_EXTERNAL_DB}" ]
then
   echo "Attempting to import the database."
   if [ ! -d "${hostconfig}/mysql/import/$dir" ]; then mkdir -p ${hostconfig}/mysql/import/$dir; fi
   if [ ! -f "${hostconfig}/mysql/import/$dir/mysql-dump-file.sql" ]; then 
      source ${drushscripts}/fetch_external_db.sh
      fetch_external_db ${hostconfig}/mysql/import/$dir/mysql-dump-file.sql || true && chown -R www-data:www-data ${hostconfig}/mysql/import/$dir || true
   fi
   if drush sql-cli < ${hostconfig}/mysql/import/$dir/mysql-dump-file.sql; 
   then 
      echo "Database import successful"
   else 
      echo "Database import unseccessful. Most likely the result of my code sucking." && true
   fi
fi

# Install backup and migrate
echo "Enabling backup and migrate module .... "
drush en backup_migrate -y || true

chmod u+w ${DRUPAL_SETTINGS} ${DRUPAL_LOCAL_SETTINGS}

echo
echo "      Drupal is now configured"
echo
echo
echo "    Drupal installed successfully."
echo
echo "      Drupal admin login: admin"
echo "   Drupal admin password: $adminpass"
echo 
echo "Don't forget to change your drupal admin password!"
echo ""
done
