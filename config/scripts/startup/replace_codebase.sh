#!/bin/bash

CODEBASEDIR=${SITEROOT}/../codebase
function replace_codebase {
    if [ -f "$1" ]
    then
        mv -f $1 ${CODEBASEDIR}/codebase.tar.gz || true
        cd ${CODEBASEDIR} && tar -p -xz --strip-components=1 --keep-newer-files -f codebase.tar.gz
        rm codebase.tar.gz && cd ${SITEROOT}
    fi
    rsync -a ${CODEBASEDIR}/ ${SITEROOT}/ || true && chown -R www-data:www-data ${SITEROOT}
    rm -rf ${CODEBASEDIR:?}/* ${CODEBASEDIR}/.* || true;
} 
