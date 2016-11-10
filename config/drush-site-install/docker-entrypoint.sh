#!/bin/bash
set -a

apt-get update -y || true
apt-get install inotify-tools -y

while true
do 
inotifywait -e modify,close_write,move,create,delete ${SITEROOT}/sites && install_drupal
done
