#!/bin/bash

export add_this_to_settings=$(cat <<END
#
# Add include statement for local.settings.php
#
$drupalenv = getenv('DRUPAL_ENVIRONMENT');
if (empty($drupalenv)) $drupalenv = "local";
$localsettings = $drupalenv.'.settings.php';
if (is_readable(dirname(__FILE__) . DIRECTORY_SEPARATOR . $localsettings)) {
    include dirname(__FILE__) . DIRECTORY_SEPARATOR . $localsettings;
}

END
); 

echo "${add_this_to_settings}" >> ${DRUPAL_SETTINGS} && chown www-data:www-data ${DRUPAL_SETTINGS}
