#!/bin/bash

VAR_SYSTEM_MAIL_DIR="/var/qmail/mailnames"
VAR_SYSTEM_HOSTNAME=$(hostname)

VAR_STATISTICS_MAIL_COUNT_TOTAL=$(tree -a $VAR_SYSTEM_MAIL_DIR | grep -c $VAR_SYSTEM_HOSTNAME)

PrintStatistics(){
    echo "===== MAIL STATISTICS ====="
    echo " - The Total Mail Count is: $VAR_STATISTICS_MAIL_COUNT_TOTAL"
    echo ""
}

PrintStatistics

for var_domain in "$VAR_SYSTEM_MAIL_DIR"/*; do
    echo "Processing Domain: $(basename $var_domain)..."
    for var_email_address in "$var_domain"/*; do
        if [ -d $var_email_address ]; then
            echo " - $(basename "$var_email_address")@$(basename "$var_domain"): $(tree -a $var_email_address | grep -c $VAR_SYSTEM_HOSTNAME)"
        fi
    done
    echo "Done!"
    echo
done