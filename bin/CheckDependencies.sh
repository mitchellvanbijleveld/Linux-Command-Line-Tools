#!/bin/bash

echoDebug "Dependency check will happen here..."
echoDebug "The following dependencies will be checked: '$@'..."

for var_script_dependency in $@; do
    if [ $(which "$var_script_dependency") ]; then
        echoDebug "Dependency '$var_script_dependency' found!"
    else
        echo "Dependency '$var_script_dependency' was not found on this system. Exiting..."
        exit 1
    fi
done