#!/bin/bash
set -a

function replace_codebase {

    # By default we'll assume the sync-from directory is "Codebase," unless specified as an argument to the function.
    local syncfrom="${CODEBASEDIR}";
    
    if [ ! -d "$1" ]; then
       if [ ! -d "${CODEBASEDIR}" ]; then mkdir -p ${CODEBASEDIR} || true; fi
    else
       syncfrom="$1";
    fi
    
    if [ -f "$1" ]; then
       mv -f $1 ${syncfrom}/codebase.tar.gz || true
       cd ${syncfrom} && tar -p -xz --strip-components=1 --keep-newer-files -f codebase.tar.gz || true
       rm codebase.tar.gz || true && cd ${SITEROOT}
    fi

    rsync -a ${syncfrom}/ ${SITEROOT}/ || true
    rm -rf ${syncfrom:?}/* ${syncfrom}/.* || true;
} 
