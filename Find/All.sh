#!/bin/bash
VAR_UTILITY="Find"
VAR_UTILITY_SCRIPT="All"
VAR_UTILITY_SCRIPT_VERSION="2024.08.23-1127"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="clear echo find PrintMessage sort"

if [[ $1 == "" ]]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Search Parameter not set! Exiting..."
    exit 1
fi

clear; sudo find / -iname "*$1*" | sort 