#!/bin/bash
# Fetch the remote database

# $ only applies to remote server variables
function get_external_db_siteroot {
   export EXTERNAL_DB_SITEROOT=$(echo $(ssh -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_SRC_IP} '
   if [ -d "/etc/apache2" ]; then 
      greping=$(grep "DocumentRoot " /etc/apache2 -R | sed -n "1 p" | xargs)
      echo ${greping#*DocumentRoot}
   fi
   if [ -d "/etc/nginx" ]; then
      greping=$(grep "root " /etc/nginx/sites-enabled -R | sed -n "1 p" | xargs)
      echo ${greping#*root}
   fi
   '))
}
if [ -z $EXTERNAL_DB_SITEROOT ]; then get_external_db_siteroot; fi

# local variables are expanded by $, so anything specific to the remote server is excaped with \
function fetch_external_db_path {
   export LATESTFILE=$(echo $(ssh -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_SRC_IP} bash -c "'
   # Get the file name of the latest backup from backup and migrate. 
   cd ${EXTERNAL_DB_SRC_SITEROOT}/sites/$DIR
   # 1. Start by calling drush bam-backups to get a list of backup files and grab just the first line of those results.
   firstline=\$( drush bam-backups | awk 'FNR == 2 {print}' | xargs )
   # 2. Get just the file name from the first line of results
   set -- \$firstline && backupfile=\$1
   # 3. Get the full, absolute path to that file
   readlink -f \$(find files/private/backup_migrate -name \${backupfile})
   '"))
}
