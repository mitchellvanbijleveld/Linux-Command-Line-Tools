#!/bin/bash
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="echo git"
"$(which bash)" "$VAR_BIN_INSTALL_DIR/bin/CheckDependencies.sh" "$VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS" || { exit 1; }

echo "Updating..."
echo ""
git -C "$VAR_SCRIPT_INSTALL_DIR" pull
echo ""
echo "Done"