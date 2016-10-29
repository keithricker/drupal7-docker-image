#!/bin/bash
# Fetch the remote database

# Get the document root of the remote server if it doesn't exist as an environment variable
function get_ext_siteroot {
   if [ -d "/etc/apache2" ]; then 
      greping=$(grep "Document Root " /etc/apache2 -R | sed -n '1 p')
      export EXTERNAL_DB_SRC_SITEROOT=${greping#*DocumentRoot} | xargs   
   fi
   if [ -d "/etc/nginx" ]; then
      greping=$(grep "root " /etc/nginx/sites-enabled -R | sed -n '1 p')
      export EXTERNAL_DB_SRC_SITEROOT=${greping#*root} | xargs
   fi
}

# Get the file name of the latest backup from backup and migrate. I'm sure there is a less verbose way of doing this,
# but unfortunately I'm not much of a bash expert.

# Navigate to the corresponding "site" directory
remotecommand="cd ${EXTERNAL_DB_SRC_SITEROOT}/sites/$dir && "
# 1. Start by calling drush bam-backups to get a list of backup files and grab just the first line of those results.
remotecommand+="firstline=\$(drush bam-backups | sed -n '2p' | xargs) &&"
# 2. Get just the file name from the first line of results
remotecommand+='set -- $firstline && backupfile=$1 && '
# 3. Get the full, absolute path to that file
remotecommand+='backupfile=$(readlink -f $(find files/private/backup_migrate -name ${backupfile})) && echo $backupfile'
   
LATEST_FILE=$(ssh -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_SRC_IP} "${remotecommand}")
scp -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_SRC_IP}:${LATEST_FILE} ~/mysql-dump-file.sql

if drush sql-cli < ~/my-sql-dump-file.sql; 
then 
   echo "Database import successful" && continue
else 
   echo "Database import unseccessful. Most likely the result of my code sucking."
fi
