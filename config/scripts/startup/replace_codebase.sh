#!/bin/bash

CODEBASEDIR=${SITEROOT}/../codebase
function replace_codebase {
    if [ -f "$1" ]
    then
        mv -f $1 ${CODEBASEDIR}/codebase.tar.gz || true
        cd ${CODEBASEDIR} && tar -xz --strip-components=1 -f --keep-newer-files -p codebase.tar.gz
        rm codebase.tar.gz && cd ${SITEROOT}
    fi
    rsync -a ${CODEBASEDIR}/ ${SITEROOT}/ || true && chown -r www-data:www-data ${SITEROOT}
    rm -r ${CODEBASEDIR:?}/* ${CODEBASEDIR}/.* || true;
} 
