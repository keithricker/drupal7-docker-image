#!/bin/bash

echo "entering the start script ...."

# Copy shared files from server container to docker host machine for sharing
hostscripts=/root/host_app/config/scripts
localscripts=/root/config/scripts
startupscripts=${hostscripts}/startup
CURRENTFILE=$(readlink -f "$0")
CURRENTFILENAME=$( basename "$0" )
TARGETFILE=${startupscripts}/${CURRENTFILENAME}
CURRENTDIR=$(dirname "${CURRENTFILE}")

if [ "${CURRENTDIR}" == "${localscripts}/startup" ]
then
    # Move anything newer from the container to the host, and delete anything in the existing config folder.
    rsync -a /root/config /root/host_app || true
    bash ${TARGETFILE}
    rm -rf /root/config/* /root/config/.* || true
    mkdir -p ${CURRENTDIR} && cp -f ${TARGETFILE} ${CURRENTFILE} || true
    exit 0
fi

# Edit apache config files to listen on port specified in env variable.
bash /root/host_app/config/apache/set_listen_port.sh
# Start memcache
service memcached start || true
# Start Apache Solr
service tomcat7 start || true

# If there is a private key defined in the env vars, then add it.
bash ${startupscripts}/copy_private_key.sh

# Include the replace_codebase function.
source ${startupscripts}/replace_codebase.sh

#If there is already existing code and no git repo is defined, then exit out
if [ -f "${SITEROOT}/modules/node/node.module" ]; then drupal_files_exist=true; fi
if [ -f "${SITEROOT}/sites/default/local.settings.php" ]; then drupal_already_configured=true; fi
if [ "${GIT_REPO}" != "" ]; then git_repo_exists=true; fi

# Yes this is more code than necessary but it makes things esier to follow along with.
if [ "$drupal_already_configured" == "true" ] && [ ! "$git_repo_exists" ]; then move_along=true; fi
if [ "$drupal_files_exist" ] && [ "$git_repo_exists" ]; then pull_from_git=true; fi
if [ ! "$drupal_files_exist" ] && [ "$git_repo_exists" ]; then clone_from_git=true; fi
if [ ! "$drupal_files_exist" ] && [ ! "$git_repo_exists" ]; then install_drupal_from_scratch=true; fi

#If there is already existing code and no git repo is defined, then exit out
if [ "$move_along" ]; then echo "Code already exists, site is configured and nothing to update. All set here." && exit 0; fi

# If we're downloading drupal from scratch, then set our variables to specify the source and version.
if [ "$install_drupal_from_scratch" ]
then 
    # If there is a tarred archive of our codebase, then unpack it.
    if [ -f "${CODEBASEDIR}/codebase.tar.gz" ]
    then 	
        echo "Expanding codebase .... "
        replace_codebase ${CODEBASEDIR}/codebase.tar.gz
        drupal_files_exist=true;
    else
        echo "We need to download drupal from scratch ... "
        git_repo_exists=true
        clone_from_git=true
        GIT_REPO="${DRUPAL_SOURCE}"
        GIT_BRANCH="${DRUPAL_VERSION}"
    fi
fi

# Clone or pull our repo from GIT, etc.
source ${startupscripts}/git_commands.sh
grab_git_repo -branch ${GIT_BRANCH} -repo ${GIT_REPO} -target ${CODEBASEDIR} -newbranch ${MAKE_GIT_BRANCH}

cd ${SITEROOT} && chown -R www-data:www-data ${SITEROOT}

# Getting ready to install drupal. First we'll define a bunch of default variables, including database credentials, etc.
# ... as well as variables for our files, private and temp directories, etc.
source ${startupscripts}/drupal_config_variables.sh

# create some directories and set permissions
bunchodirs=( ${DRUPAL_TMP_DIR} ${DRUPAL_FILES_DIR} ${DRUPAL_PRIVATE_DIR} )
for cooldir in ${bunchodirs[@]};
do
if [ ! -d "$cooldir" ]
then
  mkdir -p $cooldir
  chmod 775 $cooldir
  chown -R www-data:www-data $cooldir
fi
done
chmod -R 664 ${DRUPAL_PRIVATE_DIR}

for dir in ${DRUPAL_SITE_DIR}/*/;
do
# get the name of the current directory and assign it to dir
dir=${dir%*/}
dir=${dir##*/}
DRUPAL_DEFAULT_SETTINGS=${DRUPAL_SITE_DIR}/$dir/default.settings.php
DRUPAL_SETTINGS=${DRUPAL_SITE_DIR}/$dir/settings.php
DRUPAL_LOCAL_SETTINGS=${DRUPAL_SITE_DIR}/$dir/local.settings.php

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
   drupalsitename=drupalsitename-${dbname}
else
   source ${startupscripts}/drupal_config_variables.sh
fi

#
# Install the site
# Drush won't install the site if there is an existing settings.php file. So we'll do this as a work-around
#
cd ${DRUPAL_SITE_DIR}/$dir

echo ""
echo "Creating a new Drupal site at ${DRUPAL_SITE_DIR}/$dir"
echo ""

# If we're establishing a connection and we have data, then we'll assume we're installed and we'll move along.
if drush pm-info node --fields=status; then echo "Site is already installed here. Moving along." && continue; else true; fi

if [ ! -f "${DRUPAL_SETTINGS}" ]; then 
    cp -rp ../default/default.settings.php settings.php
fi

includestring="\$localsettings = \$drupalenv.'.settings.php"
if ! grep "$includestring" ${DRUPAL_SETTINGS};
then
   source ${startupscripts}/modify_settings_file_1.sh
fi
cp ${hostscripts}/../local.settings.php local.settings.php && chown www-data:www-data local.settings.php

echo "Attempting to import the database."

# Temporarily rename drush directory so it's configuration doesn't interfere with installing site.
if [ -d "drush" ]; then mv drush drush_bk; fi;

if [ "$dir" != "default" ]; 
then
    sed -i -e -c 's/$src['\''MYSQL_ENV_MYSQL_DATABASE'\'']/'${dbname}'/g' local.settings.php
    cd ../default && drush sql-create --db-url=mysql://$dbuname:$dbpass@$dbhost:$dbport/$dbname --yes || true;
    if [ -z $IMPORT_EXTERNAL_DB ]; then
        if [ ! -f "defaultdb.sql" ]; then drush sql-dump --result-file=defaultdb.sql || true; fi
        cd ../${dir} && drush sql-cli < ../default/defaultdb.sql || true;
    fi
else
    if [ -z $IMPORT_EXTERNAL_DB ]; then 
        mv settings.php settings.php.bak
        if ! drush site-install minimal --site-name=${drupalsitename} --account-pass=$adminpass --db-url=mysql://$dbuname:$dbpass@$dbhost:$dbport/$dbname --yes
        then
           echo "Unable to configure your Drupal installation at $DRUPAL_SITE_DIR/$dir"
           echo "" && true
        fi
        rm setting.php || true && mv settings.php.bak settings.php
    else 
        drush sql-create --db-url=mysql://$dbuname:$dbpass@$dbhost:$dbport/$dbname --yes || true;
    fi
fi

chown -R www-data:www-data ${DRUPAL_SITE_DIR}

# If we're importing an external database, then we'll attempt to connect to the external server and grab it.
if [ "${IMPORT_EXTERNAL_DB}" ]
then
   echo "Attempting to import the database."
   source ${startupscripts}/import_external_db.sh
fi

# Bring back the drush directory now that we're done installing site.
if [ -d "drush.bak" ]; then mv drush.bak drush;

echo "Just got done installing site ... "

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
echo
done

cd ${SITEROOT}

# Additional commands can be added by an environment variable
echo "Checking for additional command ... "
if [[ "$ADDITIONAL_COMMAND" != "" && "$ADDITIONAL_COMMAND" != "null" ]]
then
    echo "Running additional command ..."
    y=`eval $ADDITIONAL_COMMAND`
    echo $y
fi

# Remove drush and composer if not in dev mode
if [ ! ${DEVELOPMENT_MODE} ]
then
   rm /usr/bin/drush || true
   rm /usr/local/bin/composer || true
   rm -r /root/.composer || true
fi
