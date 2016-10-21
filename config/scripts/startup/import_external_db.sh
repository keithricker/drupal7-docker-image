#!/bin/bash

# Fetch the remote database
remotecommand="ls -1rth ${EXTERNAL_DB_SITEROOT}/sites/default/files/private/backup_migrate/scheduled/*.mysql.gz | tail -1"   
LATEST_FILE=$(ssh -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_IP} "${remotecommand}")
scp -i ~/.ssh/${PRIVATE_KEY_FILE} ${EXTERNAL_DB_USER}@${EXTERNAL_DB_IP}:${LATEST_FILE} ~/mysql-dump-file.sql

if drush sql-cli < ~/my-sql-dump-file.sql; then echo "Database import successful" && continue; else echo "Database import unseccessful"; fi
