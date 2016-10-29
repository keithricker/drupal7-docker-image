#!/bin/bash
# Fetch the remote database

function get_external_db_siteroot {
   ssh -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_SRC_IP} bash -c "'
   if [ -d "/etc/apache2" ]; then 
      greping=$(grep "Document Root " /etc/apache2 -R | sed -n \'1 p\')
      export EXTERNAL_DB_SITEROOT=${greping#*DocumentRoot} | xargs   
   fi
   if [ -d "/etc/nginx" ]; then
      greping=$(grep "root " /etc/nginx/sites-enabled -R | sed -n \'1 p\')
      export EXTERNAL_DB_SITEROOT=${greping#*root} | xargs
   fi
   '"
}

if [ -z $EXTERNAL_DB_SITEROOT ]; then get_external_db_siteroot; fi

ssh -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_SRC_IP} bash -c "'

# Get the file name of the latest backup from backup and migrate. 
cd ${EXTERNAL_DB_SRC_SITEROOT}/sites/$dir
# 1. Start by calling drush bam-backups to get a list of backup files and grab just the first line of those results.
firstline=$(drush bam-backups | sed -n \'2p\' | xargs)
# 2. Get just the file name from the first line of results
set -- $firstline && backupfile=$1
# 3. Get the full, absolute path to that file
export LATESTFILE=$(readlink -f $(find files/private/backup_migrate -name ${backupfile}))
'"

scp -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_SRC_IP}:${LATEST_FILE} ~/mysql-dump-file.sql

if drush sql-cli < ~/my-sql-dump-file.sql; 
then 
   echo "Database import successful" && continue
else 
   echo "Database import unseccessful. Most likely the result of my code sucking."
fi
