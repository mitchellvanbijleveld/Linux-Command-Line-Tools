#!/bin/bash

echoDebug "Dependency check will happen here..."
echoDebug "The following dependencies will be checked: '$@'..."

for var_script_dependency in $@; do
    if type "$var_script_dependency" &> /dev/null; then
        echoDebug "Dependency '$var_script_dependency' found!"
    else
        echoInfo "Dependency '$var_script_dependency' was not found on this system. Exiting..."
        exit 1
    fi
done