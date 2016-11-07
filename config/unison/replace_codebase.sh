#!/bin/bash
set -a

if [ ! -d "${CODEBASEDIR}" ]; then mkdir -p ${CODEBASEDIR} && chown -R www-data:www-data ${CODEBASEDIR}; fi

function replace_codebase {
    if [ -f "$1" ]
    then
        mv -f $1 ${CODEBASEDIR}/codebase.tar.gz || true
        cd ${CODEBASEDIR} && tar -p -xz --strip-components=1 --keep-newer-files -f codebase.tar.gz
        rm codebase.tar.gz && cd ${SITEROOT}
    fi
    rsync -a ${CODEBASEDIR}/ ${SITEROOT}/ || true && chown -R www-data:www-data ${SITEROOT} || true
    rm -rf ${CODEBASEDIR:?}/* ${CODEBASEDIR}/.* || true;
} 
