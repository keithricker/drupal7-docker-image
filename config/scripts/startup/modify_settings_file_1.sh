#!/bin/bash

read -d '' output <<- EOF
#
# Add include statement for local.settings.php
#
$drupalenv = getenv('DRUPAL_ENVIRONMENT');
if (empty($drupalenv)) $drupalenv = "local";
$localsettings = $drupalenv.'.settings.php';
if (is_readable(dirname(__FILE__) . DIRECTORY_SEPARATOR . $localsettings)) {
    include dirname(__FILE__) . DIRECTORY_SEPARATOR . $localsettings;
}

EOF 
echo "$output" >> ${DRUPAL_SETTINGS}