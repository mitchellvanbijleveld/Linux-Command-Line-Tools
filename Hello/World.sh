#!/bin/bash
VAR_UTILITY="Hello"
VAR_UTILITY_SCRIPT="World"

VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="echo"
"$(which bash)" "$VAR_BIN_INSTALL_DIR/bin/CheckDependencies.sh" "$VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS" || { exit 1; }

echoInfo
echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Hello, World! If you see this message, the Linux Command Line Tools are working as expected!"
if ! [[ "$@" == "" ]]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "The script is run with the following arguments: '$@'."
else
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Try adding some flags (--FLAG) to see if they are recognized!"
fi
echoInfo