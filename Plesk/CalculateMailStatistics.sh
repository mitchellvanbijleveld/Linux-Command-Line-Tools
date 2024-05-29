#!/bin/bash
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="basename echo find grep hostname tree sort"
"$(which bash)" "$VAR_BIN_INSTALL_DIR/bin/CheckDependencies.sh" "$VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS" || { exit 1; }

VAR_SYSTEM_MAIL_DIR="/var/qmail/mailnames"
VAR_SYSTEM_HOSTNAME=$(hostname)

VAR_STATISTICS_MAIL_COUNT_TOTAL=$(tree -a $VAR_SYSTEM_MAIL_DIR | grep -c $VAR_SYSTEM_HOSTNAME)

VAR_SCRIPT_STATISTICS_DIR="$VAR_BIN_TEMP_DIR/$VAR_UTILITY/$VAR_UTILITY_SCRIPT/statistics"
"$(which rm)" -r "$VAR_SCRIPT_STATISTICS_DIR"
"$(which mkdir)" -p "$VAR_SCRIPT_STATISTICS_DIR"

declare -A VAR_STATISTICS
VAR_STATISTICS["INBOX"]=0
VAR_STATISTICS["SPAM"]=0
VAR_STATISTICS["SENT"]=0

declare -A VAR_STATISTICS_MAIL_PER_DATE_INBOX
declare -A VAR_STATISTICS_MAIL_PER_DATE_SPAM
declare -A VAR_STATISTICS_MAIL_PER_DATE_SENT

PrintStatistics(){
    echoInfo "===== MAIL STATISTICS ====="
    echoInfo "The Total Mail Count is: $VAR_STATISTICS_MAIL_COUNT_TOTAL"
    for var_mail_box_count in "${!VAR_STATISTICS[@]}"; do
        echoInfo " - $var_mail_box_count: ${VAR_STATISTICS[$var_mail_box_count]}"
    done
    echoInfo ""
    echoInfo "The total amount of email addresses: $(ls $VAR_SCRIPT_STATISTICS_DIR | grep -c '@')"
    for var_email_address_string_file_path in "$VAR_SCRIPT_STATISTICS_DIR"/*; do
        string_total=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/total"))
        string_inbox=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/inbox"))
        string_spam=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/spam"))
        string_sent=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/sent"))
        echoInfo " - $(basename $var_email_address_string_file_path): "
        echoInfo "   $string_total (Inbox: $string_inbox, Spam: $string_spam, Sent: $string_sent)"
    done
    echoInfo ""
    echoInfo "Mail Per Date:"
    echoInfo " - Inbox"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_INBOX[@]}"; do echo "$date"; done | sort); do
        echoInfo "   $date: ${VAR_STATISTICS_MAIL_PER_DATE_INBOX[$date]}"
    done
    echoInfo " - Spam"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_SPAM[@]}"; do echo "$date"; done | sort); do
        echoInfo "   $date: ${VAR_STATISTICS_MAIL_PER_DATE_SPAM[$date]}"
    done
    echoInfo " - Sent"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_SENT[@]}"; do echo "$date"; done | sort); do
        echoInfo "   $date: ${VAR_STATISTICS_MAIL_PER_DATE_SENT[$date]}"
    done
    echoInfo ""
}

WriteStatistics(){
    # $1 = email address
    # $2 = count total
    # $3 = count inbox
    # $4 = count spam
    # $5 = count sent

    "$(which mkdir)" -p "$VAR_SCRIPT_STATISTICS_DIR/$1"

    echo "$2" > "$VAR_SCRIPT_STATISTICS_DIR/$1/total"
    echo "$3" > "$VAR_SCRIPT_STATISTICS_DIR/$1/inbox"
    echo "$4" > "$VAR_SCRIPT_STATISTICS_DIR/$1/spam"
    echo "$5" > "$VAR_SCRIPT_STATISTICS_DIR/$1/sent"

}

for var_domain in "$VAR_SYSTEM_MAIL_DIR"/*; do
    echoDebug "Processing Domain: $(basename $var_domain)..."
    for var_email_address in "$var_domain"/*; do
        if [ -d $var_email_address ]; then
            var_email_address_string=$(basename "$var_email_address")@$(basename "$var_domain")

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

            echoDebug " - $var_email_address_string $var_statistics_mail_count_total $var_statistics_mail_count_inbox $var_statistics_mail_count_spam $var_statistics_mail_count_sent"

            # Write statistics to file
            WriteStatistics "$var_email_address_string" "$var_statistics_mail_count_total" "$var_statistics_mail_count_inbox" "$var_statistics_mail_count_spam" "$var_statistics_mail_count_sent"

        fi
    done
    echoDebug "Done!"
    echoDebug
done

PrintStatistics