#!/bin/bash
VAR_UTILITY="bin"
VAR_UTILITY_SCRIPT="CheckDependencies"


echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Dependency check has been started..."

CheckDependency(){
    # $1 string dependency
    # $2 bool exit

    if type "$1" &> /dev/null; then
        echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Dependency OK     : $(printf "%-10s\n" "$1")"
    else
        echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Dependency NOT OK : $(printf "%-10s\n" "$1")"
        if $2; then
            echoInfo "Dependency '$1' was not found on this system. Exiting..."
            exit 1
        else
            DependencyMissing=True
        fi
    fi

}

if [[ "$@" ]]; then
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Checking specified dependencies. Exiting upon failure..."
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "The following dependencies will be checked: '$@'..."

    for var_script_dependency in $@; do
        CheckDependency "$var_script_dependency" true
    done
else
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Checking all utility script dependencies..."

    VAR_COMMAND_LINE_TOOLS_TO_INSTALL="$VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS"

    for var_utility in "$VAR_BIN_INSTALL_DIR"/*; do
        echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Processing utility '$(basename $var_utility)'..."
        for var_utility_script in "$var_utility"/*; do
            echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Processing utility script '$(basename ${var_utility_script%.sh})'..."
            if ! [ -f "$var_utility_script" ]; then
                echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Not a valid file ('${var_utility_script%.sh}')! Skipping..."
                continue
            fi
            for var_cli in $(eval $(grep "^VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS=" $var_utility_script); echo $VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS); do
                echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Found '$var_cli' in '$(basename $var_utility)/$(basename ${var_utility_script%.sh})'!"
                if ! [[ "$VAR_COMMAND_LINE_TOOLS_TO_INSTALL" == *"$var_cli"* ]]; then
                    VAR_COMMAND_LINE_TOOLS_TO_INSTALL="$VAR_COMMAND_LINE_TOOLS_TO_INSTALL $var_cli"
                fi
            done
        done
    done

    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Necessary command line utilities in order to work correctly: '$VAR_COMMAND_LINE_TOOLS_TO_INSTALL'"

    for var_script_dependency in $VAR_COMMAND_LINE_TOOLS_TO_INSTALL; do
        CheckDependency "$var_script_dependency" false
    done

    if ! $DependencyMissing; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Dependencies OK!"
        exit 0
    else
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Dependencies NOT OK!"
        exit 1
    fi
fi