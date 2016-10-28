#!/bin/bash

function grab_git_repo() {

    # If git repo environment variable is defined and there is no existing code, then clone from that repo.
    git config --global --unset https.proxy && git config --global --unset http.proxy;

    local args=( $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ) && index=0   
    for myarg in "${args[@]}"; do
       if [[ $myarg == -* ]]
       then
          argname=${myarg#?}
          eval "local ${argname}=${args[((index+1))]}"
       fi    
       ((index++))
    done
    
    if [ ! -d "${target}" ]; then mkdir -p ${target} && chown www-data:www-data ${target}; fi
    prev=$PWD && cd ${target}
    # clone the repo if it exists and we havent already downloaded drupal
    if [ "$clone_from_git" ]
    then
       echo "cloning from git ... "
       rm -rf ${target:?}/* ${target}/.* || true && git clone -b ${branch} ${repo} .
    else
        # Otherwise if code exists, then we assume we are pulling instead.
        if [ "$pull_from_git" ]; then cd ${SITEROOT} && git pull || true; fi
    fi 
    # Allow for creating a new branch if specified in the configuration or docker run command.
    if [ "$newbranch" ]
    then
       git checkout -b ${newbranch} || true
       git push origin ${newbranch} || true
    fi
    
    if [ -f "${CODEBASEDIR}/index.php" ]; then replace_codebase || true; fi
    cd ${prev}
}
