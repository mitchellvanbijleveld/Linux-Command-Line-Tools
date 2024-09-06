#!/bin/bash
VAR_UTILITY="Daemon"
VAR_UTILITY_SCRIPT="Stop"
VAR_UTILITY_SCRIPT_VERSION="2024.XX.XX-XXXX"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="echo sed"

# Utility Script Variables
VAR_DAEMON_NAME="$1"
VAR_DAEMON_CONFIG_FILE=$(echo "$VAR_UTILITY_SCRIPT_CONFIG_DIR" | sed "s/$VAR_UTILITY_SCRIPT/$VAR_DAEMON_NAME/")
VAR_DAEMON_PID_FILE=$(echo "$VAR_UTILITY_SCRIPT_TEMP_DIR" | sed "s/$VAR_UTILITY_SCRIPT/$VAR_DAEMON_NAME/")

if [[ $VAR_DAEMON_NAME == "" ]]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "No Daemon specified. Exiting..."
    exit 1
fi

echo $VAR_DAEMON_CONFIG_FILE
echo $VAR_DAEMON_PID_FILE

if [[ ! -f "$VAR_DAEMON_CONFIG_FILE" ]]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Daemon '$VAR_DAEMON_NAME' does not have a config file. Exiting..."
    exit 1
fi

if [[ -f "$VAR_DAEMON_PID_FILE" ]]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Daemon '$VAR_DAEMON_NAME' already running. Exiting..."
    VAR_PID=$(cat "$VAR_DAEMON_PID_FILE")
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "PID = $VAR_PID"
    #exit 1
fi

kill $VAR_PID
rm "$VAR_DAEMON_PID_FILE"




