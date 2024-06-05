#!/bin/bash
VAR_UTILITY="Plesk"
VAR_UTILITY_SCRIPT="CalculateMailStatistics"

VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="basename echo find grep hostname mysql sort tree"
"$(which bash)" "$VAR_BIN_INSTALL_DIR/bin/CheckDependencies.sh" "$VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS" || { exit 1; }

VAR_SYSTEM_MAIL_DIR="/var/qmail/mailnames"
VAR_SYSTEM_HOSTNAME=$(hostname)

if ! [ -d "$VAR_SYSTEM_MAIL_DIR" ]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Expected directory in '$VAR_SYSTEM_MAIL_DIR'. Exiting..."
    echoInfo
    exit 1
fi

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

declare -A VAR_STATISTICS_MAIL_PER_DATE_INBOX_DB
declare -A VAR_STATISTICS_MAIL_PER_DATE_SPAM_DB
declare -A VAR_STATISTICS_MAIL_PER_DATE_SENT_DB

PrintStatistics_FileSystem(){
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "===== MAIL STATISTICS ====="
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "The Total Mail Count is: $VAR_STATISTICS_MAIL_COUNT_TOTAL"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Inbox : ${VAR_STATISTICS["INBOX"]}"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Spam  : ${VAR_STATISTICS["SPAM"]}"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Sent  : ${VAR_STATISTICS["SENT"]}"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "The total amount of email addresses: $(ls $VAR_SCRIPT_STATISTICS_DIR | grep -c '@')"
    for var_email_address_string_file_path in "$VAR_SCRIPT_STATISTICS_DIR"/*; do
        string_total=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/total"))
        string_inbox=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/inbox"))
        string_spam=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/spam"))
        string_sent=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/sent"))
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - $(basename $var_email_address_string_file_path): "
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "   $string_total (Inbox: $string_inbox, Spam: $string_spam, Sent: $string_sent)"
    done
    echoInfo
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Mail Per Date:"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Inbox"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_INBOX[@]}"; do echo "$date"; done | sort); do
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "   $date: ${VAR_STATISTICS_MAIL_PER_DATE_INBOX[$date]}"
    done
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Spam"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_SPAM[@]}"; do echo "$date"; done | sort); do
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "   $date: ${VAR_STATISTICS_MAIL_PER_DATE_SPAM[$date]}"
    done
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Sent"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_SENT[@]}"; do echo "$date"; done | sort); do
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "   $date: ${VAR_STATISTICS_MAIL_PER_DATE_SENT[$date]}"
    done
    echoInfo
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
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Processing Domain: $(basename $var_domain)..."
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

            echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - $var_email_address_string $var_statistics_mail_count_total $var_statistics_mail_count_inbox $var_statistics_mail_count_spam $var_statistics_mail_count_sent"

            # Write statistics to file
            WriteStatistics "$var_email_address_string" "$var_statistics_mail_count_total" "$var_statistics_mail_count_inbox" "$var_statistics_mail_count_spam" "$var_statistics_mail_count_sent"

        fi
    done
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Done!"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT"
done

PrintStatistics_FileSystem



var_db_query_stats="SELECT * FROM stats"
var_db_query_stats_accounts="SELECT * FROM stats_accounts"
var_db_query_stats_daily_volume="SELECT * FROM stats_daily_volume"

PrintStatistics_Database(){
    result_var_db_query_stats=$("$(which mysql)" -u root -D emailsecurity -Bse "$var_db_query_stats")
    result_var_db_query_stats_accounts=$("$(which mysql)" -u root -D emailsecurity -Bse "$var_db_query_stats_accounts")
    result_var_db_query_stats_daily_volume=$("$(which mysql)" -u root -D emailsecurity -Bse "$var_db_query_stats_daily_volume")

    while IFS= read -r mail_per_date; do
        VAR_STATISTICS_MAIL_PER_DATE_INBOX_DB["$(echo "$mail_per_date" | awk '{print $1}')"]="$(echo "$mail_per_date" | awk '{print $2}')"
        VAR_STATISTICS_MAIL_PER_DATE_SPAM_DB["$(echo "$mail_per_date" | awk '{print $1}')"]="$(echo "$mail_per_date" | awk '{print $3}')"
        VAR_STATISTICS_MAIL_PER_DATE_SENT_DB["$(echo "$mail_per_date" | awk '{print $1}')"]="$(echo "$mail_per_date" | awk '{print $5}')"
    done <<< "$result_var_db_query_stats_daily_volume"

    var_result_db_receivedHam=$(echo $result_var_db_query_stats | awk '{print $2}')
    var_result_db_receivedSpam=$(echo $result_var_db_query_stats | awk '{print $4}')
    var_result_db_sentHam=$(echo $result_var_db_query_stats | awk '{print $8}')

    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "===== MAIL STATISTICS FROM DATABASE ====="
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "The Total Mail Count is: $(($var_result_db_receivedHam + $var_result_db_receivedSpam + $var_result_db_sentHam))"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Received Ham  : $var_result_db_receivedHam"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Received Spam : $var_result_db_receivedSpam"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Sent Ham      : $var_result_db_sentHam"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT"

    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Mail Per Date:"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Inbox"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_INBOX_DB[@]}"; do echo "$date"; done | sort); do
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "   $date: ${VAR_STATISTICS_MAIL_PER_DATE_INBOX_DB[$date]}"
    done
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Spam"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_SPAM_DB[@]}"; do echo "$date"; done | sort); do
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "   $date: ${VAR_STATISTICS_MAIL_PER_DATE_SPAM_DB[$date]}"
    done
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Sent"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_SENT_DB[@]}"; do echo "$date"; done | sort); do
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "   $date: ${VAR_STATISTICS_MAIL_PER_DATE_SENT_DB[$date]}"
    done
    echoInfo

}

PrintStatistics_Database

CompareStatistics(){

    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "===== MAIL STATISTICS COMPARISON ====="

    if [[ $var_result_db_receivedHam == ${VAR_STATISTICS["INBOX"]} ]]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Inbox : OK"
    else
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Inbox : NOT OK"
    fi
    if [[ $var_result_db_receivedSpam == ${VAR_STATISTICS["SPAM"]} ]]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Spam  : OK"
    else
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Spam  : NOT OK"
    fi
    if [[ $var_result_db_sentHam == ${VAR_STATISTICS["SENT"]} ]]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Sent  : OK"
    else
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Sent  : NOT OK"
    fi
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT"

    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Inbox"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_INBOX[@]}"; do echo "$date"; done | sort); do
        if [[ ${VAR_STATISTICS_MAIL_PER_DATE_INBOX[$date]} == ${VAR_STATISTICS_MAIL_PER_DATE_INBOX_DB[$date]} ]]; then
            echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  $date : OK"
        else
            echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  $date : NOT OK"
        fi
    done
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Spam"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_SPAM[@]}"; do echo "$date"; done | sort); do
        if [[ ${VAR_STATISTICS_MAIL_PER_DATE_SPAM[$date]} == ${VAR_STATISTICS_MAIL_PER_DATE_SPAM_DB[$date]} ]]; then
            echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  $date : OK"
        else
            echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  $date : NOT OK"
        fi
    done
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Sent"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_SENT[@]}"; do echo "$date"; done | sort); do
        if [[ ${VAR_STATISTICS_MAIL_PER_DATE_SENT[$date]} == ${VAR_STATISTICS_MAIL_PER_DATE_SENT_DB[$date]} ]]; then
            echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  $date : OK"
        else
            echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  $date : NOT OK"
        fi
    done







}

CompareStatistics