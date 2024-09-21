#!/bin/bash
VAR_UTILITY="bin"
VAR_UTILITY_SCRIPT="update"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="echo git"


PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Updating..."
PrintMessage "INFO"
git -C "$VAR_BIN_INSTALL_DIR" pull
PrintMessage "INFO"
PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Done"