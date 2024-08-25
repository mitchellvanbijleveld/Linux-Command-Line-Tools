#!/bin/bash
VAR_UTILITY="Plesk"
VAR_UTILITY_SCRIPT="CalculateMailStatistics"
VAR_UTILITY_SCRIPT_VERSION="2024.07.12-1240"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="basename echo find grep hostname mysql sort tree"

VAR_STATISTICS_FAIL=0

VAR_SYSTEM_MAIL_DIR="/var/qmail/mailnames"
VAR_SYSTEM_HOSTNAME=$(hostname)

if ! [ -d "$VAR_SYSTEM_MAIL_DIR" ]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Expected directory in '$VAR_SYSTEM_MAIL_DIR'. Exiting..."
    echoInfo
    exit 1
fi

VAR_STATISTICS_MAIL_COUNT_TOTAL=$(tree -a $VAR_SYSTEM_MAIL_DIR | grep -c $VAR_SYSTEM_HOSTNAME)

if [[ "$@" == *"--verbose"* ]]; then
    VAR_SCRIPT_VERBOSE=1
else
    VAR_SCRIPT_VERBOSE=0
fi



if [[ "$@" == *"--run-update-statistics-script"* ]]; then
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Running script to update statistics in database..."
    sudo -u psaadm /opt/psa/admin/bin/php -dauto_prepend_file=sdk.php '/opt/psa/admin/plib/modules/email-security/scripts/update-stats.php'
fi

VAR_SCRIPT_STATISTICS_DIR="$VAR_UTILITY_SCRIPT_TEMP_DIR/statistics"
if [ -d "$VAR_SCRIPT_STATISTICS_DIR" ]; then
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Removing directory '$VAR_SCRIPT_STATISTICS_DIR'..."
    "$(which rm)" -r "$VAR_SCRIPT_STATISTICS_DIR"
fi
echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Creating directory '$VAR_SCRIPT_STATISTICS_DIR'..."
"$(which mkdir)" -p "$VAR_SCRIPT_STATISTICS_DIR"

declare -A VAR_STATISTICS
VAR_STATISTICS["INBOX"]=0
VAR_STATISTICS["SPAM"]=0
VAR_STATISTICS["SENT"]=0
VAR_STATISTICS["DRAFTS"]=0

declare -A VAR_STATISTICS_MAIL_PER_DATE_INBOX
declare -A VAR_STATISTICS_MAIL_PER_DATE_SPAM
declare -A VAR_STATISTICS_MAIL_PER_DATE_SENT
declare -A VAR_STATISTICS_MAIL_PER_DATE_DRAFTS

declare -A VAR_STATISTICS_MAIL_PER_DATE_INBOX_DB
declare -A VAR_STATISTICS_MAIL_PER_DATE_SPAM_DB
declare -A VAR_STATISTICS_MAIL_PER_DATE_SENT_DB

WriteStatistics(){
    # $1 = email address
    # $2 = count total
    # $3 = count inbox
    # $4 = count spam
    # $5 = count sent
    # $6 = count drafts

    "$(which mkdir)" -p "$VAR_SCRIPT_STATISTICS_DIR/$1"

    echo "$2" > "$VAR_SCRIPT_STATISTICS_DIR/$1/total"
    echo "$3" > "$VAR_SCRIPT_STATISTICS_DIR/$1/inbox"
    echo "$4" > "$VAR_SCRIPT_STATISTICS_DIR/$1/spam"
    echo "$5" > "$VAR_SCRIPT_STATISTICS_DIR/$1/sent"
    echo "$6" > "$VAR_SCRIPT_STATISTICS_DIR/$1/drafts"

}

for var_domain in "$VAR_SYSTEM_MAIL_DIR"/*; do
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Processing Domain: $(basename $var_domain)..."
    for var_email_address in "$var_domain"/*; do
        if [ -d $var_email_address ]; then
            var_email_address_string=$(basename "$var_email_address")@$(basename "$var_domain")

            var_statistics_mail_count_total=$(tree -a -I '.Drafts' $var_email_address | grep -c $VAR_SYSTEM_HOSTNAME)
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

            var_statistics_mail_count_drafts=$(tree -a "$var_email_address/Maildir/.Drafts/" | grep -c $VAR_SYSTEM_HOSTNAME)
            ((VAR_STATISTICS["DRAFTS"]+=var_statistics_mail_count_drafts))
            while IFS= read -r date; do
                    ((VAR_STATISTICS_MAIL_PER_DATE_DRAFTS["$date"]++))
                    ((VAR_STATISTICS_MAIL_PER_DATE_INBOX["$date"]--))
            done < <(find "$var_email_address/Maildir/.Drafts/" -type f -iname "*$VAR_SYSTEM_HOSTNAME*" -printf '%TY-%Tm-%Td\n')

            echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - $var_email_address_string $var_statistics_mail_count_total $var_statistics_mail_count_inbox $var_statistics_mail_count_spam $var_statistics_mail_count_sent $var_statistics_mail_count_drafts"

            # Write statistics to file
            WriteStatistics "$var_email_address_string" "$var_statistics_mail_count_total" "$var_statistics_mail_count_inbox" "$var_statistics_mail_count_spam" "$var_statistics_mail_count_sent" "$var_statistics_mail_count_drafts"

        fi
    done
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Done!"
    echoDebug
done



var_db_query_stats="SELECT * FROM stats"
var_db_query_stats_accounts="SELECT * FROM stats_accounts"
var_db_query_stats_daily_volume="SELECT * FROM stats_daily_volume"

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




PrintStatistics_FileSystem_Header(){
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "##### STATISTICS ACCORDING TO FILE SYSTEM #####"
}
PrintStatistics_FileSystem_PerMailBox(){
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Total Mail Count (File System)  : $VAR_STATISTICS_MAIL_COUNT_TOTAL"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Total Mail Count      Inbox  : ${VAR_STATISTICS["INBOX"]}"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Total Mail Count      Spam   : ${VAR_STATISTICS["SPAM"]}"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Total Mail Count      Sent   : ${VAR_STATISTICS["SENT"]}"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Total Mail Count      Drafts : ${VAR_STATISTICS["DRAFTS"]}"
    echoInfo 
}
PrintStatistics_FileSystem_PerEmailAddress(){
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Total Amount Of Email Addresses (File System) : $(ls $VAR_SCRIPT_STATISTICS_DIR | grep -c '@')"
    for var_email_address_string_file_path in "$VAR_SCRIPT_STATISTICS_DIR"/*; do
        string_total=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/total"))
        string_inbox=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/inbox"))
        string_spam=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/spam"))
        string_sent=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/sent"))
        string_drafts=$(printf "%5d\n" $(cat "$var_email_address_string_file_path/drafts"))
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - $(basename $var_email_address_string_file_path): "
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "   $string_total (Inbox: $string_inbox, Spam: $string_spam, Sent: $string_sent, Drafts: $string_drafts)"
    done
    echoInfo
}
PrintStatistics_FileSystem_PerDate(){
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Statistics Per Date (File System):"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Date      : Inbox |  Spam |  Sent | Drafts"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_INBOX[@]}"; do echo "$date"; done | sort); do
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "   $date: $(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_INBOX[$date]}) | $(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_SPAM[$date]}) | $(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_SENT[$date]}) | $(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_DRAFTS[$date]})"
    done
    echoInfo
}
PrintStatistics_FileSystem(){
    PrintStatistics_FileSystem_Header
    PrintStatistics_FileSystem_PerMailBox
    PrintStatistics_FileSystem_PerEmailAddress
    PrintStatistics_FileSystem_PerDate
}


PrintStatistics_Database_Header(){
 echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "##### STATISTICS ACCORDING TO DATABASE ###########"
}
PrintStatistics_Database_PerMailBox(){
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Total Mail Count (Fetched From Database) : $(($var_result_db_receivedHam + $var_result_db_receivedSpam + $var_result_db_sentHam))"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "- Total Mail Count         Received Ham  : $var_result_db_receivedHam"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "- Total Mail Count         Received Spam : $var_result_db_receivedSpam"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "- Total Mail Count         Sent Ham      : $var_result_db_sentHam"
    echoInfo
}
PrintStatistics_Database_PerEmailAddress(){
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Total Amount Of Email Addresses (Database) : [not implemented yet]"
    while IFS= read -r email_address; do
        string_inbox=$(printf "%5d\n" $(echo "$email_address" | awk '{print $2}'))
        string_spam=$(printf "%5d\n" $(echo "$email_address" | awk '{print $3}'))
        string_sent=$(printf "%5d\n" $(echo "$email_address" | awk '{print $5}'))
        string_total=$(printf "%5d\n" $(($string_inbox + $string_spam + $string_sent)))
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - $(echo "$email_address" | awk '{print $1}'): "
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "   $string_total (Inbox: $string_inbox, Spam: $string_spam, Sent: $string_sent)"
    done <<< "$result_var_db_query_stats_accounts"
    echoInfo  
}
PrintStatistics_Database_PerDate(){
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Statistics Per Date (Database):"
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Date      : Inbox |  Spam |  Sent"
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_INBOX_DB[@]}"; do echo "$date"; done | sort); do
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "   $date: $(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_INBOX_DB[$date]}) | $(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_SPAM_DB[$date]}) | $(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_SENT_DB[$date]})"
    done
    echoInfo
}
PrintStatistics_Database(){
    PrintStatistics_Database_Header
    PrintStatistics_Database_PerMailBox
    PrintStatistics_Database_PerEmailAddress
    PrintStatistics_Database_PerDate
}












PrintStatistics_Comparison_Header(){
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "===== MAIL STATISTICS COMPARISON ====="
}
PrintStatistics_Comparison_PerMailBox(){
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "# Comparison per mailbox"
    if [[ $var_result_db_receivedHam == ${VAR_STATISTICS["INBOX"]} ]]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Inbox  : OK : $(printf "%5d\n" ${VAR_STATISTICS["INBOX"]})"
    else
        VAR_STATISTICS_FAIL=1
        echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Inbox (db vs fs) : $var_result_db_receivedHam vs ${VAR_STATISTICS["INBOX"]}"
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Inbox  : NOT OK"
    fi
    if [[ $var_result_db_receivedSpam == ${VAR_STATISTICS["SPAM"]} ]]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Spam   : OK : $(printf "%5d\n" ${VAR_STATISTICS["SPAM"]})"
    else
        VAR_STATISTICS_FAIL=1
        echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Inbox (db vs fs) : $var_result_db_receivedSpam vs ${VAR_STATISTICS["SPAM"]}"
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Spam   : NOT OK"
    fi
    if [[ $var_result_db_sentHam == ${VAR_STATISTICS["SENT"]} ]]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Sent   : OK : $(printf "%5d\n" ${VAR_STATISTICS["SENT"]})"
    else
        VAR_STATISTICS_FAIL=1
        echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Inbox (db vs fs) : $var_result_db_sentHam vs ${VAR_STATISTICS["SENT"]}"
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Sent   : NOT OK"
    fi
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Drafts : ?? : $(printf "%5d\n" ${VAR_STATISTICS["DRAFTS"]})"
    echoInfo 
}
PrintStatistics_Comparison_PerEmailAddress(){
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "# Comparison per email address"
    while IFS= read -r email_address; do
        string_inbox_db=$(printf "%5d\n" $(echo "$email_address" | awk '{print $2}'))
        string_spam_db=$(printf "%5d\n" $(echo "$email_address" | awk '{print $3}'))
        string_sent_db=$(printf "%5d\n" $(echo "$email_address" | awk '{print $5}'))
        string_total_db=$(printf "%5d\n" $(($string_inbox_db + $string_spam_db + $string_sent_db)))

        string_total_fs=$(printf "%5d\n" $(cat "$VAR_SCRIPT_STATISTICS_DIR/$(echo "$email_address" | awk '{print $1}')/total"))
        string_inbox_fs=$(printf "%5d\n" $(cat "$VAR_SCRIPT_STATISTICS_DIR/$(echo "$email_address" | awk '{print $1}')/inbox"))
        string_spam_fs=$(printf "%5d\n" $(cat "$VAR_SCRIPT_STATISTICS_DIR/$(echo "$email_address" | awk '{print $1}')/spam"))
        string_sent_fs=$(printf "%5d\n" $(cat "$VAR_SCRIPT_STATISTICS_DIR/$(echo "$email_address" | awk '{print $1}')/sent"))

        echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Total (db vs fs) : $string_total_db vs $string_total_fs"
        echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Inbox (db vs fs) : $string_inbox_db vs $string_inbox_fs"
        echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Spam  (db vs fs) : $string_spam_db vs $string_spam_fs"
        echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Sent  (db vs fs) : $string_sent_db vs $string_sent_fs"

        if [[ $string_total_db == $string_total_fs ]] && [[ $string_inbox_db == $string_inbox_fs ]] && [[ $string_spam_db == $string_spam_fs ]] && [[ $string_sent_db == $string_sent_fs ]]; then
            if [[ $VAR_SCRIPT_VERBOSE -eq 1 ]] || $VAR_SCRIPT_DEBUG; then
                echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " -     OK: $(echo "$email_address" | awk '{print $1}')"
            fi
        else
            FAIL_EMAILADDRESS=1
            VAR_STATISTICS_FAIL=1
            if [[ $VAR_SCRIPT_VERBOSE -eq 1 ]] || $VAR_SCRIPT_DEBUG; then
                echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - NOT OK: $(echo "$email_address" | awk '{print $1}')"
            fi
        fi
    done <<< "$result_var_db_query_stats_accounts"

    if [[ $FAIL_EMAILADDRESS -eq 1 ]] && [[ $VAR_SCRIPT_VERBOSE -eq 0 ]]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  NOT OK"
    elif [[ $FAIL_EMAILADDRESS -eq 0 ]] && [[ $VAR_SCRIPT_VERBOSE -eq 0 ]]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  OK"
    fi


    echoInfo





}
PrintStatistics_Comparison_PerDate(){
    VAR_FAIL_DATE=0
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Comparison Per Date:"
    if [[ $VAR_SCRIPT_VERBOSE -eq 1 ]]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" " - Date       : Inbox  | Spam   | Sent   "
    fi
    for date in $(for date in "${!VAR_STATISTICS_MAIL_PER_DATE_INBOX_DB[@]}"; do echo "$date"; done | sort); do
        # Reset Status Text per date.
        var_text_inbox="  OK  "
        var_text_spam="  OK  "
        var_text_sent="  OK  "

        var_stats_inbox_db=$(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_INBOX_DB[$date]})
        var_stats_inbox_fs=$(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_INBOX[$date]})
        if [[ $var_stats_inbox_db -ne $var_stats_inbox_fs ]]; then
            VAR_STATISTICS_FAIL=1
            VAR_FAIL_DATE=1
            var_text_inbox="NOT OK"
        fi
        var_stats_spam_db=$(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_SPAM_DB[$date]})
        var_stats_spam_fs=$(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_SPAM[$date]})
        if [[ $var_stats_spam_db -ne $var_stats_spam_fs ]]; then
            VAR_STATISTICS_FAIL=1
            VAR_FAIL_DATE=1
            var_text_spam="NOT OK"
        fi
        var_stats_sent_db=$(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_SENT_DB[$date]})
        var_stats_sent_fs=$(printf "%5d\n" ${VAR_STATISTICS_MAIL_PER_DATE_SENT[$date]})
        if [[ $var_stats_sent_db -ne $var_stats_sent_fs ]]; then
            VAR_STATISTICS_FAIL=1
            VAR_FAIL_DATE=1
            var_text_sent="NOT OK"
        fi
        if [[ $VAR_SCRIPT_VERBOSE -eq 1 ]]; then
            echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "   $date : $var_text_inbox | $var_text_spam | $var_text_sent "
        fi
    done
    if [[ $VAR_FAIL_DATE -eq 1 ]] && [[ $VAR_SCRIPT_VERBOSE -eq 0 ]]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  NOT OK"
    elif [[ $VAR_FAIL_DATE -eq 0 ]] && [[ $VAR_SCRIPT_VERBOSE -eq 0 ]]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  OK"
    fi
    echoInfo
}
PrintStatistics_Comparison(){
    PrintStatistics_Comparison_Header
    PrintStatistics_Comparison_PerMailBox
    PrintStatistics_Comparison_PerEmailAddress
    PrintStatistics_Comparison_PerDate
}








if [[ "$@" == *"--print-statistics-filesystem"* ]]; then
    PrintStatistics_FileSystem
fi

if [[ "$@" == *"--print-statistics-database"* ]]; then
    PrintStatistics_Database
fi

#if [[ "$@" == *"--print-statistics-comparison"* ]]; then
    PrintStatistics_Comparison
#fi

if [[ "$@" == *"--print-statistics-per-mailbox"* ]]; then
    PrintStatistics_FileSystem_PerMailBox
    PrintStatistics_Database_PerMailBox
fi
if [[ "$@" == *"--print-statistics-per-emailaddress"* ]]; then
    PrintStatistics_FileSystem_PerEmailAddress
    PrintStatistics_Database_PerEmailAddress
fi
if [[ "$@" == *"--print-statistics-per-date"* ]]; then
    PrintStatistics_FileSystem_PerDate
    PrintStatistics_Database_PerDate
fi





if [[ $VAR_SCRIPT_VERBOSE -eq 1 ]]; then
    echo "verbose flag"
fi

if [[ $VAR_STATISTICS_FAIL -eq 0 ]]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "FileSystem vs DataBase: OK! The statistics calculated from the filesystem match the statistics from the database."
elif [[ $VAR_STATISTICS_FAIL -eq 1 ]]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "FileSystem vs DataBase: NOT OK! The statistics calculated from the filesystem do not match the statistics from the database."
fi