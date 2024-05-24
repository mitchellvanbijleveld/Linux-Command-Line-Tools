#!/bin/bash
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="echo"
"$(which bash)" "$VAR_BIN_INSTALL_DIR/bin/CheckDependencies.sh" "$VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS" || { exit 1; }

echo
echo "Hello, World! When you see this message, the Linux Command Line Tools are working as expected!"
if ! [[ "$@" == "" ]]; then
    echo "This is script is ran with the following arguments: '$@'."
fi
echo