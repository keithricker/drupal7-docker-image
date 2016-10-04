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
fi

# Additional commands can be added by an environment variable
echo "Checking for additional command ... "
if [ "$ADDITIONAL_COMMAND" != "" ] && [ "$ADDITIONAL_COMMAND" != "null" ];
    then
    echo "Running additional command ..."
    y=`eval $ADDITIONAL_COMMAND`
    echo $y;
fi
