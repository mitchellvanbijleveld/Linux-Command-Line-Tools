#!/bin/bash
VAR_UTILITY="Daemon"
VAR_UTILITY_SCRIPT="Install"
VAR_UTILITY_SCRIPT_VERSION="2024.09.09-2048"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="cp echo PrintMessage sed"

# Utility Script Variables
VAR_DAEMON_NAME="$1"
VAR_DAEMON_CONFIG_FILE=$(echo "$VAR_UTILITY_SCRIPT_CONFIG_DIR" | sed "s/$VAR_UTILITY_SCRIPT/$VAR_DAEMON_NAME/")
VAR_DAEMON_EXAMPLE_FILE="$VAR_UTILITY_FOLDER_PATH/Examples/$VAR_DAEMON_NAME"

if [[ $VAR_DAEMON_NAME == "" ]]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "No Daemon specified. Exiting..."
    exit 1
fi

PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" $VAR_DAEMON_CONFIG_FILE
PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" $VAR_DAEMON_EXAMPLE_FILE

if [[ -f "$VAR_DAEMON_CONFIG_FILE" ]] && [[ $@ != *"--replace"* ]]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Daemon '$VAR_DAEMON_NAME' already installed. Exiting..."
    exit 1
fi

if [[ ! -f "$VAR_DAEMON_EXAMPLE_FILE" ]]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Daemon '$VAR_DAEMON_NAME' does not exist as an example. Exiting..."
    exit 1
fi

cp -v $VAR_DAEMON_EXAMPLE_FILE $VAR_DAEMON_CONFIG_FILE

exit 0