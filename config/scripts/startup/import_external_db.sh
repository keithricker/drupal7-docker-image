#!/bin/bash
# Fetch the remote database

# Get the file name of the latest backup from backup and migrate. I'm sure there is a less verbose way of doing this,
# but unfortunately I'm not much of a bash expert.

# Navigate to the corresponding "site" directory
remotecommand = "cd ${EXTERNAL_DB_SITEROOT}/sites/$dir && "
# 1. Start by calling drush bam-backups to get a list of backup files and grab just the first line of those results.
remotecommand+="firstline=\$(drush bam-backups | sed -n '2p' | xargs) &&"
# 2. Get just the file name from the first line of results
remotecommand+='set -- $firstline && backupfile=$1 && '
# 3. Get the full, absolute path to that file
remotecommand+='backupfile=$(readlink -f $(find files/private/backup_migrate -name ${backupfile})) && echo $backupfile'
   
LATEST_FILE=$(ssh -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_IP} "${remotecommand}")
scp -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_IP}:${LATEST_FILE} ~/mysql-dump-file.sql

if drush sql-cli < ~/my-sql-dump-file.sql; 
then 
   echo "Database import successful" && continue
else 
   echo "Database import unseccessful. Most likely the result of my code sucking."
fi
