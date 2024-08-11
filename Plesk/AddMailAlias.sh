#!/bin/bash
VAR_UTILITY="Plesk"
VAR_UTILITY_SCRIPT="AddMailAlias"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="echo plesk"

VAR_EMAIL_ADDRESS=$2
VAR_EMAIL_ADDRESS_ALIAS=$1

if [[ $VAR_EMAIL_ADDRESS == "" ]]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Please provide an email address!"
    exit 1
fi

if [[ $VAR_EMAIL_ADDRESS_ALIAS == "" ]]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Please provide an alias for this email address!"
    exit 1
fi

VAR_EMAIL_ADDRESS_NEW_WITH_ALIAS="$VAR_EMAIL_ADDRESS_ALIAS@$(echo "$VAR_EMAIL_ADDRESS" | awk -F '@' '{print $2}')"

echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Adding alias '$VAR_EMAIL_ADDRESS_ALIAS' to email address '$VAR_EMAIL_ADDRESS'..."
echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "New email address / alias: '$VAR_EMAIL_ADDRESS_NEW_WITH_ALIAS'."
plesk bin mail -u "$VAR_EMAIL_ADDRESS" -aliases "add:$VAR_EMAIL_ADDRESS_ALIAS"