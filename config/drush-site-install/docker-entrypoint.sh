#!/bin/bash
set -a

apt-get update -y || true
apt-get install inotify-tools -y

while true
do 
inotifywait -r -e modify,close_write,move,create,delete ${SITEROOT}/sites/default && install_drupal
done
