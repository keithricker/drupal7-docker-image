#!/bin/bash

if [ "${PRIVATE_KEY_CONTENTS}" != "" ]
then
    echo "Copying over the private key."
    echo "${PRIVATE_KEY_CONTENTS}" > ~/.ssh_copy/${PRIVATE_KEY_FILE}
    sed -i 's/\\n/\
/g' ~/.ssh_copy/${PRIVATE_KEY_FILE}
    chmod 600  ~/.ssh_copy/${PRIVATE_KEY_FILE} || true
fi
rsync -a ~/.ssh_copy/ /root/.ssh || true && chown -R root:root /root/.ssh || true
