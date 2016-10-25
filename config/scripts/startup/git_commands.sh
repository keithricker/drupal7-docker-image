#!/bin/bash

function grab_git_repo() {

    # If git repo environment variable is defined and there is no existing code, then clone from that repo.
    git config --global --unset https.proxy && git config --global --unset http.proxy;

    local args=( $1 $2 $3 $4 $5 $6 $7 $8 $9 $10 ) && index=0   
    for myarg in ${args[@]}; do
       if [[ $myarg == -* ]]
       then
          argname=${myarg#?}
          eval "local ${argname}=${args[((index+1))]}"
       fi    
       ((index++))
    done

    # clone the repo if it exists and we havent already downloaded drupal
    if [ "$clone_from_git" ]
    then
       echo "cloning from git ... "
       git clone -b ${branch} ${repo} ${target}
       replace_codebase 
    fi
    # Otherwise if code exists, then we assume we are pulling instead.
    if [ "$pull_from_git" ]; 
    then git pull ${repo} origin ${branch} ${target} && replace_codebase || true; 
    fi
      
    # Allow for creating a new branch if specified in the configuration or docker run command.
    if [ "$newbranch" ]
    then
       git checkout -b ${newbranch} || true
       git push origin ${newbranch} || true
    fi
   
}
