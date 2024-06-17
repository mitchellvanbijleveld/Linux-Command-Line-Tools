#!/bin/bash
VAR_UTILITY="bin"
VAR_UTILITY_SCRIPT="update"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="echo git"


echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Updating..."
echoInfo
git -C "$VAR_BIN_INSTALL_DIR" pull
echoInfo
echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Done"