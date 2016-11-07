#!/bin/bash
set -a

# Copy all environment variables from linked containers to main
"$(printenv)[@]"|while read line; do 
    modline=export $(sed "s/APPSERVER_//g" <<< $line) | xargs
    statement="export $modline"
    eval ${statement}
done

# Include drupal variables
drupalscripts=/host_app/config/scripts
source ${drupalscripts}/drupal_config_variables.sh

# If there is a private key defined in the env vars, then add it. Otherwise, copy over the host app user's private key.
bash ${busyboxscripts}/copy_private_key.sh

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

# Clone or pull our repo from GIT, etc.
source ${busyboxscripts}/git_commands.sh
grab_git_repo -branch ${GIT_BRANCH} -repo ${GIT_REPO} -target ${CODEBASEDIR} -newbranch ${MAKE_GIT_BRANCH} || true
