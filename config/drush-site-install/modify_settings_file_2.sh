#!/bin/bash

function replace_settings_vars {
   # Just replacing some variables in the settings.php files with hard values
   revisedsettings=$(cat $1);
   replaceme=(dbname dbuname dbpass dbhost dbport)

   for replacement in "${replaceme[@]}"; do
      replaceval=$( eval 'echo $'${replacement} )
      revisedsettings=$(sed "s/${replacement}/${replaceval}/"<<<"$revisedsettings")
   done

   echo "$revisedsettings" > $1
}
