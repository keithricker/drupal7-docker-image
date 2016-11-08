#!/bin/bash

# Give full permissions to our user
echo "GRANT ALL ON *.* TO '$MYSQL_USER'@'%' WITH GRANT OPTION;" | "${mysql[@]}"
