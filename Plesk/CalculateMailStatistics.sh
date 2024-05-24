#!/bin/bash

VAR_SYSTEM_MAIL_DIR="/var/qmail/mailnames"
VAR_SYSTEM_HOSTNAME=$(hostname)

VAR_STATISTICS_MAIL_COUNT_TOTAL=$(tree -a $VAR_SYSTEM_MAIL_DIR | grep -c $VAR_SYSTEM_HOSTNAME)

PrintStatistics(){
    echo "===== MAIL STATISTICS ====="
    echo " - The Total Mail Count is: $VAR_STATISTICS_MAIL_COUNT_TOTAL"
}

PrintStatistics