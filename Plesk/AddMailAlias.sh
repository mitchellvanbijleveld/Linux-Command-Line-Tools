#!/bin/bash
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="echo plesk"
"$(which bash)" "$VAR_BIN_INSTALL_DIR/bin/CheckDependencies.sh" "$VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS" || { exit 1; }

VAR_EMAIL_ADDRESS=$1
VAR_EMAIL_ADDRESS_ALIAS=$2

if [[ $VAR_EMAIL_ADDRESS == "" ]]; then
    echo "Please provide an email address!"
    exit 1
fi

if [[ $VAR_EMAIL_ADDRESS_ALIAS == "" ]]; then
    echo "Please provide an alias for this email address!"
    exit 1
fi

VAR_EMAIL_ADDRESS_NEW_WITH_ALIAS="$VAR_EMAIL_ADDRESS_ALIAS@$(echo "$VAR_EMAIL_ADDRESS" | awk -F '@' '{print $2}')"

echo "Adding alias '$VAR_EMAIL_ADDRESS_ALIAS' to email address '$VAR_EMAIL_ADDRESS'..."
echo "New email address / alias: '$VAR_EMAIL_ADDRESS_NEW_WITH_ALIAS'."
plesk bin mail -u "$VAR_EMAIL_ADDRESS" -aliases "add:$VAR_EMAIL_ADDRESS_ALIAS"