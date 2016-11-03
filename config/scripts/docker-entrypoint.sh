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
    mkdir -p /host_app/config/drupal
fi
if [ -d "/root/config" ]; then
    drupalscripts=/host_app/config/drupal/scripts
    rsync -a -u /root/config/ /host_app/config/drupal || true 
    rm -rf /root/config || true
    rm /usr/local/bin/docker-entrypoint && ln -s ${drupalscripts}/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
fi

# Define a bunch of variables
source /host_app/config/drupal/scripts/drupal_config_variables.sh

# Edit apache config files to listen on port specified in env variable, and start apache.
nohup bash /host_app/config/drupal/apache/apache_start.sh || true

# Start memcache
service memcached start || true

# If there is a private key defined in the env vars, then add it.
bash ${drupalscripts}/copy_private_key.sh

# Include the replace_codebase function.
source ${drupalscripts}/replace_codebase.sh

#If there is already existing code and no git repo is defined, then exit out
if [ -f "${SITEROOT}/modules/node/node.module" ]; then drupal_files_exist=true; fi
if [ -f "${SITEROOT}/sites/default/local.settings.php" ]; then drupal_already_configured=true; fi
if [ "${GIT_REPO}" != "" ]; then git_repo_exists=true; fi

# Yes this is more code than necessary but it makes things esier to follow along with.
if [ "$drupal_already_configured" == "true" ] && [ ! "$git_repo_exists" ] && [ "$INSTALL_DRUPAL" != "true" ]; then move_along=true; fi
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
source ${drupalscripts}/git_commands.sh
grab_git_repo -branch ${GIT_BRANCH} -repo ${GIT_REPO} -target ${CODEBASEDIR} -newbranch ${MAKE_GIT_BRANCH}

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

# If drupal isn't already installed / configured, then install it.
if [ -z $INSTALL_DRUPAL ]; then
   if [ "$drupal_already_configured" != "true" ]; then INSTALL_DRUPAL=true; fi
fi
if [ "$INSTALL_DRUPAL" == "true" ]; then source ${drupalscripts}/install_drupal.sh; fi

# Surrender ownership of the code
cd ${SITEROOT} && chown -R ${ownership} ${SITEROOT} && chown -R www-data:www-data ${SITEROOT}

# Additional commands can be added by an environment variable
echo "Checking for additional command ... "
if [[ "$ADDITIONAL_COMMAND" != "" && "$ADDITIONAL_COMMAND" != "null" ]]
then
    echo "Running additional command ..."
    y=$(eval $ADDITIONAL_COMMAND)
    echo $y
fi

# Remove drush and composer if not in dev mode
if [ ! ${DEVELOPMENT_MODE} ]
then
   rm /usr/bin/drush || true
   rm /usr/local/bin/composer || true
   rm -r /root/.composer || true
fi
