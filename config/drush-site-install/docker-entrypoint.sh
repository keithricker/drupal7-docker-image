#!/bin/bash
set -a

apt-get update -y || true
apt-get install inotify-tools -y

while true
do
inotifywait -e modify,move,create ${SITEROOT}/sites && install_drupal
done
