#!/bin/bash
VAR_UTILITY="Daemon"
VAR_UTILITY_SCRIPT="List"
VAR_UTILITY_SCRIPT_VERSION="2024.09.11-2338"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="echo echoDebug echoInfo printf sed"

# Utility Script Variables
VAR_DAEMON_LIST_OPTION="$1"
VAR_DAEMON_CONFIG_BASE_DIR=$(echo "$VAR_UTILITY_SCRIPT_CONFIG_DIR" | sed "s/$VAR_UTILITY_SCRIPT//")
VAR_DAEMON_PID_BASE_DIR=$(echo "$VAR_UTILITY_SCRIPT_TEMP_DIR" | sed "s/$VAR_UTILITY_SCRIPT//")
VAR_DAEMON_EXAMPLE_BASE_DIR="$VAR_UTILITY_FOLDER_PATH/Examples/"

if [[ $VAR_DAEMON_LIST_OPTION == "" ]]; then
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "No option specified. Defaulting to 'all'..."
    VAR_DAEMON_LIST_OPTION="ALL"
fi

echo $VAR_DAEMON_CONFIG_BASE_DIR
echo $VAR_DAEMON_PID_BASE_DIR
echo $VAR_DAEMON_LIST_OPTION

echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Daemon Name          | VERSION         | STATE"

GetDaemonVersion(){
    VAR_LINE_DAEMON_VERSION=$(grep '^VAR_DAEMON_VERSION=' "$1")
    eval "$VAR_LINE_DAEMON_VERSION"
    echo "$VAR_DAEMON_VERSION"
}

PrintRowDaemon(){
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "$(printf "%-20s" "$1") | $(printf "%-15s" "$2") | $3"
}

case $(echo "$VAR_DAEMON_LIST_OPTION" | tr '[:lower:]' '[:upper:]') in

  "ALL")
    echo "ALL NOT IMPLEMENTED"
    ;;

  "INSTALLED")
    for DaemonName in "$VAR_DAEMON_CONFIG_BASE_DIR"*; do
        if [[ -f "$DaemonName" ]]; then
            ShortDaemonName=$(basename $DaemonName)
            PrintRowDaemon "$ShortDaemonName" "$(GetDaemonVersion $DaemonName)" "Installed"
        fi
    done
    ;;

  "RUNNING")
    for DaemonName in "$VAR_DAEMON_PID_BASE_DIR"*; do
        if [[ -f "$DaemonName" ]]; then
            ShortDaemonName=$(basename $DaemonName)
            PrintRowDaemon "$ShortDaemonName" "$(cat $DaemonName)" "Running"
        fi
    done
    ;;

    "EXAMPLES")
    for DaemonName in "$VAR_DAEMON_EXAMPLE_BASE_DIR"*; do
        if [[ -f "$DaemonName" ]]; then
            ShortDaemonName=$(basename $DaemonName)
            PrintRowDaemon "$ShortDaemonName" "$(GetDaemonVersion $DaemonName)" "Available"
        fi
    done
    ;;

  *)
    echo "OTHER NOT IMPLEMENTED"
    ;;
esac

exit 0