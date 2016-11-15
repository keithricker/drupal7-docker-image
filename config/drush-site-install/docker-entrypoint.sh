#!/bin/bash
set -a

while : ; do
   [[ -f "${SITEROOT}/sites/default/settings.php" ]] && break
   sleep 5
done

sleep 60
install_drupal
exit
