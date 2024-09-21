#!/bin/bash
VAR_UTILITY="mitchellvanbijleveld"
VAR_UTILITY_SCRIPT="CheckDependencies"
VAR_UTILITY_SCRIPT_VERSION="2024.XX.XX-XXXX"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="PrintMessage"

PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Dependency check has been started..."

if [[ "$@" == *"--install-check"* ]]; then
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Script will write missing dependencies to file..."
    InstallCheck=1
fi

CheckDependency(){
    # $1 string dependency
    # $2 bool exit

    if type "$1" &> /dev/null; then
        PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Dependency OK     : $(printf "%-10s\n" "$1")"
    else
        PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Dependency NOT OK : $(printf "%-10s\n" "$1")"
        VAR_MISSING_DEPENDENCIES="$VAR_MISSING_DEPENDENCIES$1 "
        if $2; then
            PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Dependency '$1' was not found on this system. Exiting..."
            exit 1
        else
            DependencyMissing=1
        fi
    fi

}

if [[ "$@" ]] && [[ ! $InstallCheck -eq 1 ]]; then
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Checking specified dependencies. Exiting upon failure..."
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "The following dependencies will be checked: '$@'..."

    for var_script_dependency in $@; do
        CheckDependency "$var_script_dependency" true
    done
else
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Checking all utility script dependencies..."

    VAR_COMMAND_LINE_TOOLS_TO_INSTALL="$VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS"

    for var_utility in "$VAR_BIN_INSTALL_DIR"/*; do
        PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Processing utility '$(basename $var_utility)'..."
        for var_utility_script in "$var_utility"/*; do
            PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Processing utility script '$(basename ${var_utility_script%.sh})'..."
            if ! [ -f "$var_utility_script" ]; then
                PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Not a valid file ('${var_utility_script%.sh}')! Skipping..."
                continue
            fi
            for var_cli in $(eval $(grep "^VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS=" $var_utility_script); echo $VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS); do
                PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Found '$var_cli' in '$(basename $var_utility)/$(basename ${var_utility_script%.sh})'!"
                if ! [[ "$VAR_COMMAND_LINE_TOOLS_TO_INSTALL" == *"$var_cli"* ]]; then
                    VAR_COMMAND_LINE_TOOLS_TO_INSTALL="$VAR_COMMAND_LINE_TOOLS_TO_INSTALL $var_cli"
                fi
            done
        done
    done

    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Necessary command line utilities in order to work correctly: '$VAR_COMMAND_LINE_TOOLS_TO_INSTALL'"

    for var_script_dependency in $VAR_COMMAND_LINE_TOOLS_TO_INSTALL; do
        CheckDependency "$var_script_dependency" false
    done

    if ! [[ $DependencyMissing -eq 1 ]]; then
        if [[ $InstallCheck -eq 1 ]]; then
            PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Dependencies OK!"
            exit 0
        fi
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Dependencies OK!"
        exit 0
    else
        if [[ $InstallCheck -eq 1 ]]; then
            PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Writing missing dependencies to file..."
            echo "$VAR_MISSING_DEPENDENCIES" > ".mvb.missing_dependencies"
            PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "$(ls -al .mvb.missing_dependencies)"
            exit 0
        fi
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Dependencies NOT OK! Missing dependencies: $VAR_MISSING_DEPENDENCIES"
        exit 1
    fi
fi