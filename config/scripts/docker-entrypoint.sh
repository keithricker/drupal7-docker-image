#!/bin/bash
set -a

echo "entering the start script ...."

# Copy all environment variables from linked containers to main
# "$(printenv)[@]"|while read line; do 
#   modline=export $(sed "s/APPSERVER_//g" <<< $line) | xargs
#   statement="export $modline"
#   eval ${statement}
# done

# Copy shared files from server container to docker host machine for sharing
# Move anything newer from the container to the host, and delete anything in the existing config folder.

if [ ! -d "/host_app/config/appserver" ]; then
    if [ ! -d "/root/config" ]; then 
        echo "Container is not configured properly. Missing configuration directory."
        exit 0
    fi
fi
if [ -d "/root/config" ]; then    
    rsync -a -u /root/config/ /host_app/config || true 
fi

# Include drupal variables
source ${drupalscripts}/drupal_config_variables.sh

# Include the replace_codebase function.
source ${busyboxscripts}/replace_codebase.sh

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
source ${busyboxscripts}/git_commands.sh
grab_git_repo -branch ${GIT_BRANCH} -repo ${GIT_REPO} -target ${CODEBASEDIR} -newbranch ${MAKE_GIT_BRANCH}

# Define a bunch of variables
drupalscripts=/host_app/config/scripts
source ${drupalscripts}/drupal_config_variables.sh

if [ ! -f "${SITEROOT}/index.php" ] && [ -f "${CODEBASEDIR}/index.php" ]; then
    rsync -a -u ${CODEBASEDIR}/ ${SITEROOT}/ || true
fi

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

if [ -d "/host_app/config" ] && [ -d "/root/config" ]; then
   rm /usr/local/bin/docker-entrypoint && ln -s /host_app/config/scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
   rm -rf /root/config
fi
true
