#!/bin/sh

# Start memcache
service memcached start &

# If there is a private key defined in the env vars, then add it.
echo "entering the start script ...."
if [ "${PRIVATE_KEY_CONTENTS}" != "" ]; then
    echo "Copying over the private key."
    echo "${PRIVATE_KEY_CONTENTS}" > ~/.ssh/${PRIVATE_KEY_FILE}
    sed -i 's/\\n/\
/g' ~/.ssh/${PRIVATE_KEY_FILE}
    chmod 600  ~/.ssh/${PRIVATE_KEY_FILE}
    sed -i \
        -e 's/^#*\(PermitRootLogin\) .*/\1 yes/' \
        -e 's/^#*\(PasswordAuthentication\) .*/\1 yes/' \
        -e 's/^#*\(PermitEmptyPasswords\) .*/\1 yes/' \
        -e 's/^#*\(UsePAM\) .*/\1 no/' \
        /etc/ssh/sshd_config
    service ssh restart;
fi

# If a git repo is specified in the environment variable, then replace existing d7 code.
gitrepo="${GIT_REPO}";
if [ "$gitrepo" != "" ]; 
then 
    CD ${SITEROOT}/../
    echo "Pulling from repository ... "
    git config --global --unset https.proxy && git config --global --unset http.proxy
    git clone $(echo ${gitrepo}) moveme
    # Allow for creating a new branch if specified in the configuration or docker run command.
    if [ "$MAKE_GIT_BRANCH" != "" ]; 
    then
        gitbranchname=$MAKE_GIT_BRANCH
        if [ "$MAKE_GIT_BRANCH" != "" ]; then gitbranchname="$MAKE_GIT_BRANCH_NAME"; fi
        git checkout -b ${gitbranchname} || true
        git push origin ${gitbranchname} || true;
    fi
    rm -r ${SITEROOT}/* ${SITEROOT}/.* 2> /dev/null
    mv moveme/.* ${SITEROOT}/ 2> /dev/null
    mv moveme/* ${SITEROOT}/ 2> /dev/null
    rm -r moveme;
    chown -R www-data:www-data ${SITEROOT}/sites
fi

# Additional commands can be added by an environment variable
echo "Checking for additional command ... "
if [ "$ADDITIONAL_COMMAND" != "" ] && [ "$ADDITIONAL_COMMAND" != "null" ];
    then
    echo "Running additional command ..."
    y=`eval $ADDITIONAL_COMMAND`
    echo $y;
fi
