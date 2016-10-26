#!/bin/bash

addthis="\n \
#\n \
# Add include statement for local.settings.php\n\
#\n\
\$drupalenv = getenv('DRUPAL_ENVIRONMENT'); \n\
if (empty(\$drupalenv)) \$drupalenv = \"local\"; \n\
\$localsettings = \$drupalenv.'.settings.php'; \n\
if (is_readable(dirname(__FILE__) . DIRECTORY_SEPARATOR . \$localsettings)) { \n\
    include dirname(__FILE__) . DIRECTORY_SEPARATOR . \$localsettings; \n\
}"
echo "${addthis}" >> ${DRUPAL_SETTINGS} && chown www-data ${DRUPAL_SETTINGS}
