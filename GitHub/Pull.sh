#!/bin/bash
VAR_UTILITY="GitHub"
VAR_UTILITY_SCRIPT="Pull"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="echo git PrintMessage sudo"

VAR_SCRIPT_CONFIG_FILE="$VAR_UTILITY_SCRIPT_CONFIG_DIR/directories"

VAR_SYSTEM_CURRENT_DIR=$(pwd)
VAR_SYSTEM_CURRENT_USER=$(/usr/bin/whoami)

if ! [ -f "$VAR_SCRIPT_CONFIG_FILE" ]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "File with repositories does not exist. Exiting..."
    exit 1
fi

while IFS= read -r var_repository_line; do
    # Skip empty line
    if [[ "$var_repository_line" = "" ]]; then
        continue
    fi

    var_repository_user=""
    var_repository_directory=""

    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Processing Line : $var_repository_line"

    # Check if we can assume the first part is the username...
    if [[ "$(echo "$var_repository_line" | awk '{print $1}')" =~ ^[a-zA-Z0-9]+$ ]]; then
        PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Assuming the first string is a username..."
        var_repository_user=$(echo "$var_repository_line" | awk '{print $1}')
        var_repository_directory=$(echo "$var_repository_line" | sed "s/$var_repository_user//; s/^ *//; s/\"//g; s/\'//g")
        PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Repository User : $var_repository_user"
        PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Repository Dir  : $var_repository_directory"
    else
        var_repository_directory=$(echo "$var_repository_line" | sed "s/^ *//; s/\"//g; s/\'//g")
        PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Repository Dir  : $var_repository_directory"
    fi

    # Check if user is set and if the user exists on the system
    if ! [[ "$var_repository_user" = "" ]] && ! id "$var_repository_user" &>/dev/null; then
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "User '$var_repository_user' does not exist on the system. Skipping..."
        PrintMessage
        continue
    fi

    # Check if directory exists
    if ! [ -d "$var_repository_directory" ]; then
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Folder '$var_repository_directory' does not exist..."
        PrintMessage
        continue
    fi

    # Check if repository directory contains a '.git' directory
    if ! [ -d "$var_repository_directory/.git" ]; then
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Not a valid Git Repository (no '.git' direcotry detected in '$var_repository_directory')..."
        PrintMessage
        continue
    fi

    PrintMessage "DEBUG" "Ready to pull Git Repository in '$var_repository_directory'...!"

    if [[ "$var_repository_user" = "" ]]; then
        git -C "$var_repository_directory" pull
    else
        sudo -u "$var_repository_user" git -C "$var_repository_directory" pull
    fi

    PrintMessage
done < "$VAR_SCRIPT_CONFIG_FILE"