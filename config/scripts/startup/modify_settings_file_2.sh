#!/bin/bash

export add_to_settings1=$(cat <<END
/*
 * Set a base_url with correct scheme, based on the current request. This is
 * used for internal links to stylesheets and javascript.
 */
$scheme = !empty($_SERVER['REQUEST_SCHEME']) ? $_SERVER['REQUEST_SCHEME'] : 'http';
$base_url = $scheme . '://' . $_SERVER['HTTP_HOST'];

/*
 * Set the private and temp directories
 */
$conf['file_private_path'] = '<<private-directory-path>>';
$conf['file_temporary_path'] = '<<temporary-file-path>>';
END
); 

# Modifying the paths to just display the part that is relative to site root.
# i.e. sites/default/private rather than /var/www/html/sites/default/private
privatedir=${DRUPAL_PRIVATE_DIR#$SITEROOT/};
tmpdir=${DRUPAL_TMP_DIR#$SITEROOT/};

modded=$(echo "$add_to_settings1" sed -i -e -c "s/<<private-directory-path>>/${privatedir}/g")
modded=$(echo "$modded" sed -i -e -c "s/<<temporary-file-path>>/${tmpdir}/g")
echo "$modded" >> ${DRUPAL_LOCAL_SETTINGS}
chown www-data:www-data ${DRUPAL_LOCAL_SETTINGS}
