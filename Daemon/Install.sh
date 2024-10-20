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

if [[ ! -f "$VAR_DAEMON_EXAMPLE_FILE" ]]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Daemon '$VAR_DAEMON_NAME' does not exist as an example. Exiting..."
    exit 1
fi

if [[ -f "$VAR_DAEMON_CONFIG_FILE" ]]; then
    InstalledDaemonVersion=$(EvalFromFile "VAR_DAEMON_VERSION" "$VAR_DAEMON_CONFIG_FILE"; echo $VAR_DAEMON_VERSION)
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Daemon '$VAR_DAEMON_NAME' is installed with version $InstalledDaemonVersion..."
    DAEMON_UPGRADE=1
else
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Daemon '$VAR_DAEMON_NAME' not installed..."
fi


ExampleDaemonVersion=$(EvalFromFile "VAR_DAEMON_VERSION" "$VAR_DAEMON_EXAMPLE_FILE"; echo $VAR_DAEMON_VERSION)
if [[ $ExampleDaemonVersion > $InstalledDaemonVersion ]]; then
    if [[ $DAEMON_UPGRADE -eq 1 ]]; then
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Upgrading daemon '$VAR_DAEMON_NAME' from version $InstalledDaemonVersion to $ExampleDaemonVersion..."
    else
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Installing  version $ExampleDaemonVersion of daemon '$VAR_DAEMON_NAME'..."
    fi
    cp -v $VAR_DAEMON_EXAMPLE_FILE $VAR_DAEMON_CONFIG_FILE
else
    if [[ $@ == *"--replace"* ]]; then
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Replacing existing version ($ExampleDaemonVersion) of daemon '$VAR_DAEMON_NAME'..."
        cp -v $VAR_DAEMON_EXAMPLE_FILE $VAR_DAEMON_CONFIG_FILE
    else
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Daemon '$VAR_DAEMON_NAME' with version $ExampleDaemonVersion already installed. Nothing to do."
        exit 0
    fi
fi

exit 0