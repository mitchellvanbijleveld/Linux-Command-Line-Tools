#!/bin/bash
VAR_UTILITY="Daemon"
VAR_UTILITY_SCRIPT="Stop"
VAR_UTILITY_SCRIPT_VERSION="2024.09.09-2048"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="echo PrintMessage sed tmux"

# Utility Script Variables
VAR_DAEMON_NAME="$1"
VAR_DAEMON_CONFIG_FILE=$(echo "$VAR_UTILITY_SCRIPT_CONFIG_DIR" | sed "s/$VAR_UTILITY_SCRIPT/$VAR_DAEMON_NAME/")
VAR_DAEMON_PID_FILE=$(echo "$VAR_UTILITY_SCRIPT_TEMP_DIR" | sed "s/$VAR_UTILITY_SCRIPT/$VAR_DAEMON_NAME/")

if [[ $VAR_DAEMON_NAME == "" ]]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "No Daemon specified. Exiting..."
    exit 1
fi

PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" $VAR_DAEMON_CONFIG_FILE
PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" $VAR_DAEMON_PID_FILE

if [[ ! -f "$VAR_DAEMON_CONFIG_FILE" ]]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Daemon '$VAR_DAEMON_NAME' does not have a config file. Exiting..."
    exit 1
fi

if [[ ! -f "$VAR_DAEMON_PID_FILE" ]]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Daemon '$VAR_DAEMON_NAME' not running. Exiting..."
    exit 1
fi

if [[ $(echo $2 | tr '[:lower:]' '[:upper:]') == "--FORCE" ]]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Killing '$VAR_DAEMON_NAME'..."
    tmux kill-session -t $VAR_DAEMON_NAME
else
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Stopping '$VAR_DAEMON_NAME'..."
    tmux send-keys -t $VAR_DAEMON_NAME C-c
fi

rm $VAR_DAEMON_PID_FILE
exit 0