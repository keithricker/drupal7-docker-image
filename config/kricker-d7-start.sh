#!/bin/sh

# Start memcache
service memcached start &
sh /root/varnish-start.sh &

# If there is a private key defined in the env vars, then add it.
echo "entering the start script ...."
if [ "${PRIVATE_KEY_CONTENTS}" != "" ]
then
    echo "Copying over the private key."
    echo "${PRIVATE_KEY_CONTENTS}" > ~/.ssh/${PRIVATE_KEY_FILE}
    sed -i 's/\\n/\
/g' ~/.ssh/${PRIVATE_KEY_FILE}
    chmod 600  ~/.ssh/${PRIVATE_KEY_FILE}
else
    cp -a ~/.ssh_copy/. ~/.ssh/ && chown -R root:root ~/.ssh ~/.ssh/*
fi

#If there is already existing code and no git repo is defined, then exit out
if [[ -f "${SITEROOT}/sites/default/settings.php" && "${GIT_REPO}" == "" ]]
then
  echo "Code already exists. All set here."
  exit 0
fi

# If git repo environment variable is defined, then clone from that repo.
if [ "${GIT_REPO}" != "" ]
then 
   echo "Cloning git repo ${GIT_REPO}"
else
   cd ${SITEROOT}
   echo "Downloading Drupal."
   curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz
   tar -xz --strip-components=1 -f drupal.tar.gz
   rm drupal.tar.gz
   chown -R www-data:www-data sites
   downloaded_drupal=true
   echo "Drupal downloaded to site root directory."
fi

# Defnie a few variables
drupalprofile=minimal
drupalsitename=drupal7
adminpass=drupal
dbname=drupal
dbhost=database
dbuname=drupal
dbpass=drupal
dbport=3306

DRUPAL_SITE_DIR=${SITEROOT}/sites
DRUPAL_FILES_DIR=${SITEROOT}/sites/default/files
DRUPAL_PRIVATE_DIR=${SITEROOT}/sites/default/files/private
DRUPAL_TMP_DIR=${SITEROOT}/tmp

if [ "${DRUPAL_SITENAME}" != "" ]
then 
  drupalsitename="${DRUPAL_SITENAME}"
fi
if [ "$MYSQL_ENV_MYSQL_DATABASE" != "" ]
then
  dbname=$MYSQL_ENV_MYSQL_DATABASE
fi
if [ "$MYSQL_ENV_MYSQL_USER" != "" ]
then
  dbuname=$MYSQL_ENV_MYSQL_USER
fi
if [ "$MYSQL_ENV_MYSQL_USER" != "" ]
then
  dbpass=$MYSQL_ENV_MYSQL_PASSWORD
fi
if [ "$MYSQL_PORT_3306_TCP_PORT" != "" ]
then
  dbport=$MYSQL_PORT_3306_TCP_PORT
fi

# clone the repo if it exists and we havent already downloaded drupal
if [ "{downloaded_drupal}" == "" ]
then
  # start by deleting any existing code
  cd / && find ${SITEROOT} -mindepth 1 -delete && cd ${SITEROOT}
  git config --global --unset https.proxy && git config --global --unset http.proxy
  git clone $(echo ${gitrepo}) .
  # Allow for creating a new branch if specified in the configuration or docker run command.
  if [ "$MAKE_GIT_BRANCH" != "" ]; 
  then
    git checkout -b ${MAKE_GIT_BRANCH} || true
    git push origin ${MAKE_GIT_BRANCH} || true;
  fi
fi
cd ${SITEROOT}

# create some directories
if [ ! -d "${DRUPAL_TMP_DIR}" ]
then
  mkdir -p ${DRUPAL_TMP_DIR}
  chmod 775 ${DRUPAL_TMP_DIR}
  chown www-data:www-data ${DRUPAL_TMP_DIR}
fi
if [ ! -d "${DRUPAL_FIlES_DIR}" ]
then
  mkdir -p ${DRUPAL_FILES_DIR}
  chmod 775 ${DRUPAL_FILES_DIR}
  chown www-data:www-data ${DRUPAL_FILES_DIR}
fi
if [ ! -d "${DRUPAL_PRIVATE_DIR}" ]
then
  mkdir -p ${DRUPAL_PRIVATE_DIR}
  chown www-data:www-data ${DRUPAL_PRIVATE_DIR}
  chmod -R 664 ${DRUPAL_PRIVATE_DIR}
fi

for dir in ${DRUPAL_SITE_DIR}/*/;
do
# get the name of the current directory and assign it to dir
dir=${dir%*/}
dir=${dir##*/}
DRUPAL_SETTINGS=${DRUPAL_SITE_DIR}/$dir/settings.php
DRUPAL_LOCAL_SETTINGS=${DRUPAL_SITE_DIR}/$dir/local.settings.php
# break out if site is configured already or we're in sites/all
if [ "$dir" == "all" ]
then
  continue
fi
if [ -f "${DRUPAL_SITE_DIR}/$dir/local.settings.php" ]
then
  echo "Drupal is already configured in ${DRUPAL_SITE_DIR}/$dir. Delete local.settings.php to rerun setup"
  continue
fi
if [ "$dir" != "default" ]
then
  var=$dir
  dbname=${var//./}
  drupalsitename=drupalsitename-${dbname}
fi

#
# Install the site
# Drush won't install the site if there is an existing settings.php file. So we'll do this as a work-around
#
if [ -f "${DRUPAL_SETTINGS}" ] 
then
  mv ${DRUPAL_SETTINGS} ${DRUPAL_SETTINGS}.bak
fi

echo
echo "Creating a new Drupal site at ${DRUPAL_SITE_DIR}/$dir"
echo
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

# Install backup and migrate
drush en backup_migrate -y

#
# If the repo came with a settings.php file then we'll create a local.settings.php file to be included with 
# local connection details
#
if [ -f "${DRUPAL_SETTINGS}.bak" ]
then
  mv ${DRUPAL_SETTINGS} ${DRUPAL_LOCAL_SETTINGS}
  mv ${DRUPAL_SETTINGS}.bak ${DRUPAL_SETTINGS}
  chmod u+w ${DRUPAL_SETTINGS} ${DRUPAL_LOCAL_SETTINGS}
  DRUPAL_SETTINGS=$DRUPAL_LOCAL_SETTINGS
fi

#
# Set a base_url with correct scheme, based on the current request. This is
# used for internal links to stylesheets and javascript.
#
echo "\$scheme = !empty(\$_SERVER['REQUEST_SCHEME']) ? \$_SERVER['REQUEST_SCHEME'] : 'http';" >> ${DRUPAL_SETTINGS}
echo "\$base_url = \$scheme . '://' . \$_SERVER['HTTP_HOST'];" >> ${DRUPAL_SETTINGS}

#
# Set the private and temp directories
#
echo "\$conf['file_private_path'] = '$DRUPAL_PRIVATE_DIR';" >> ${DRUPAL_SETTINGS}
echo "\$conf['file_temporary_path'] = '$DRUPAL_TMP_DIR';" >> ${DRUPAL_SETTINGS}

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
done;

# Additional commands can be added by an environment variable
echo "Checking for additional command ... "
if [ "$ADDITIONAL_COMMAND" != "" ] && [ "$ADDITIONAL_COMMAND" != "null" ]
then
    echo "Running additional command ..."
    y=`eval $ADDITIONAL_COMMAND`
    echo $y;
fi

# Remove drush and composer
rm /usr/bin/drush || true
rm -r /root/.composer || true
rm /usr/local/bin/composer || true
