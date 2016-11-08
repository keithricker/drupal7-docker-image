#!/bin/bash
set -a

"$(printenv)[@]"|while read line; do 
    modline=export $(sed "s/APPSERVER_//g" <<< $line) | xargs
    statement="export $modline"
    eval ${statement}
done