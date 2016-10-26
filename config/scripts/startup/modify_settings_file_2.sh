#!/bin/bash

#
# Set a base_url with correct scheme, based on the current request. This is
# used for internal links to stylesheets and javascript.
#
echo "\$scheme = !empty(\$_SERVER['REQUEST_SCHEME']) ? \$_SERVER['REQUEST_SCHEME'] : 'http';" >> ${DRUPAL_LOCAL_SETTINGS}
echo "\$base_url = \$scheme . '://' . \$_SERVER['HTTP_HOST'];" >> ${DRUPAL_LOCAL_SETTINGS}

#
# Set the private and temp directories
#
echo "\$conf['file_private_path'] = '$DRUPAL_PRIVATE_DIR';" >> ${DRUPAL_LOCAL_SETTINGS}
echo "\$conf['file_temporary_path'] = '$DRUPAL_TMP_DIR';" >> ${DRUPAL_LOCAL_SETTINGS}
