#!/bin/bash
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="basename echo find grep hostname tree sort"
"$(which bash)" "$VAR_BIN_INSTALL_DIR/bin/CheckDependencies.sh" "$VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS" || { exit 1; }

VAR_SYSTEM_MAIL_DIR="/var/qmail/mailnames"
VAR_SYSTEM_HOSTNAME=$(hostname)

VAR_STATISTICS_MAIL_COUNT_TOTAL=$(tree -a $VAR_SYSTEM_MAIL_DIR | grep -c $VAR_SYSTEM_HOSTNAME)
VAR_STATISTICS_PROCESSED_EMAIL_ACCOUNTS=0

declare -A VAR_STATISTICS
VAR_STATISTICS["INBOX"]=0
VAR_STATISTICS["SPAM"]=0
VAR_STATISTICS["SENT"]=0
declare -A VAR_STATISTICS_EMAIL_ADDRESS

declare -A VAR_STATISTICS_MAIL_PER_DATE_INBOX
declare -A VAR_STATISTICS_MAIL_PER_DATE_SPAM
declare -A VAR_STATISTICS_MAIL_PER_DATE_SENT

PrintStatistics(){
    echo "===== MAIL STATISTICS ====="
    echo "The Total Mail Count is: $VAR_STATISTICS_MAIL_COUNT_TOTAL"
    for var_mail_box_count in "${!VAR_STATISTICS[@]}"; do
        echo " - $var_mail_box_count: ${VAR_STATISTICS[$var_mail_box_count]}"
    done
    echo ""
    echo "The total amount of email addresses: $VAR_STATISTICS_PROCESSED_EMAIL_ACCOUNTS"
    for var_email_address_string in $(for var_email_address_string in "${!VAR_STATISTICS_EMAIL_ADDRESS[@]}"; do echo "$var_email_address_string"; done | sort); do
        echo " - $var_email_address_string: ${VAR_STATISTICS_EMAIL_ADDRESS[$var_email_address_string]}"
    done
    echo ""
    echo "Mail Per Date:"
    echo " - Inbox"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_INBOX[@]}"; do echo "$date"; done | sort); do
        echo "   $date: ${VAR_STATISTICS_MAIL_PER_DATE_INBOX[$date]}"
    done
    echo " - Spam"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_SPAM[@]}"; do echo "$date"; done | sort); do
        echo "   $date: ${VAR_STATISTICS_MAIL_PER_DATE_SPAM[$date]}"
    done
    echo " - Sent"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_SENT[@]}"; do echo "$date"; done | sort); do
        echo "   $date: ${VAR_STATISTICS_MAIL_PER_DATE_SENT[$date]}"
    done
    echo

}

for var_domain in "$VAR_SYSTEM_MAIL_DIR"/*; do
    echoDebug "Processing Domain: $(basename $var_domain)..."
    for var_email_address in "$var_domain"/*; do
        if [ -d $var_email_address ]; then
            var_email_address_string=$(basename "$var_email_address")@$(basename "$var_domain")
            ((VAR_STATISTICS_PROCESSED_EMAIL_ACCOUNTS+=1))

            var_statistics_mail_count_total=$(tree -a $var_email_address | grep -c $VAR_SYSTEM_HOSTNAME)
            var_statistics_mail_count_inbox=$(tree -a -I '.Drafts|.Sent|.Spam' "$var_email_address/Maildir/" | grep -c $VAR_SYSTEM_HOSTNAME)
            ((VAR_STATISTICS["INBOX"]+=var_statistics_mail_count_inbox))
            while IFS= read -r date; do
                ((VAR_STATISTICS_MAIL_PER_DATE_INBOX["$date"]++))
            done < <(find "$var_email_address/Maildir/" -type f -iname "*$VAR_SYSTEM_HOSTNAME*" -printf '%TY-%Tm-%Td\n')

            var_statistics_mail_count_spam=$(tree -a "$var_email_address/Maildir/.Spam/" | grep -c $VAR_SYSTEM_HOSTNAME)
            ((VAR_STATISTICS["SPAM"]+=var_statistics_mail_count_spam))
            while IFS= read -r date; do
                    ((VAR_STATISTICS_MAIL_PER_DATE_SPAM["$date"]++))
                    ((VAR_STATISTICS_MAIL_PER_DATE_INBOX["$date"]--))
            done < <(find "$var_email_address/Maildir/.Spam/" -type f -iname "*$VAR_SYSTEM_HOSTNAME*" -printf '%TY-%Tm-%Td\n')

            var_statistics_mail_count_sent=$(tree -a "$var_email_address/Maildir/.Sent/" | grep -c $VAR_SYSTEM_HOSTNAME)
            ((VAR_STATISTICS["SENT"]+=var_statistics_mail_count_sent))
            while IFS= read -r date; do
                    ((VAR_STATISTICS_MAIL_PER_DATE_SENT["$date"]++))
                    ((VAR_STATISTICS_MAIL_PER_DATE_INBOX["$date"]--))
            done < <(find "$var_email_address/Maildir/.Sent/" -type f -iname "*$VAR_SYSTEM_HOSTNAME*" -printf '%TY-%Tm-%Td\n')

            var_statistics_string="$var_statistics_mail_count_total (Inbox: $var_statistics_mail_count_inbox, Spam: $var_statistics_mail_count_spam, Sent: $var_statistics_mail_count_sent)"

            echoDebug " - $var_email_address_string: $var_statistics_string"
            VAR_STATISTICS_EMAIL_ADDRESS[$var_email_address_string]="$var_statistics_string"
        fi
    done
    echoDebug "Done!"
    echoDebug
done

PrintStatistics