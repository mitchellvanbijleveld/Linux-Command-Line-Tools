#!/bin/bash
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="basename echo grep hostname tree"
"$(which bash)" "$VAR_BIN_INSTALL_DIR/bin/CheckDependencies.sh" "$VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS" || { exit 1; }

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
            var_statistics_mail_count_total=$(tree -a $var_email_address | grep -c $VAR_SYSTEM_HOSTNAME)
            var_statistics_mail_count_inbox=$(tree -a -I '.Drafts|.Sent|.Spam' "$var_email_address/Maildir/" | grep -c $VAR_SYSTEM_HOSTNAME)
            var_statistics_mail_count_spam=$(tree -a "$var_email_address/Maildir/.Spam/" | grep -c $VAR_SYSTEM_HOSTNAME)
            var_statistics_mail_count_sent=$(tree -a "$var_email_address/Maildir/.Sent/" | grep -c $VAR_SYSTEM_HOSTNAME)
            echo " - $(basename "$var_email_address")@$(basename "$var_domain"): $var_statistics_mail_count_total (Inbox: $var_statistics_mail_count_inbox, Spam: $var_statistics_mail_count_spam, Sent: $var_statistics_mail_count_sent)"
        fi
    done
    echo "Done!"
    echo
done