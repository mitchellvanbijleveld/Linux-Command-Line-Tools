#!/bin/bash
VAR_UTILITY="Server"
VAR_UTILITY_SCRIPT="BackUp"

VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="cp echo shasum sleep tar tree" # msmtp
"$(which bash)" "$VAR_BIN_INSTALL_DIR/bin/CheckDependencies.sh" "$VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS" || { exit 1; }

if [[ $(whoami) != "root" ]]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Only the 'root' user should execute this backup utility script. Exiting..."
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" ""
    exit 1
fi

VAR_SCRIPT_CONFIG_FILE="$VAR_BIN_CONFIG_DIR/$VAR_UTILITY/$VAR_UTILITY_SCRIPT/directories"
VAR_BACKUP_TEMP_DIR="$VAR_BIN_TEMP_DIR/$VAR_UTILITY/$VAR_UTILITY_SCRIPT"
VAR_BACKUP_FINAL_DIR="$VAR_BIN_CONFIG_DIR/$VAR_UTILITY/$VAR_UTILITY_SCRIPT/destination"
VAR_BACKUP_MAX_BACKUPS=4
#VAR_BACKUP_MAX_HASH_CHECKS=60
VAR_BACKUP_FILE_TYPE="tar.zst"

if ! [ -f "$VAR_BACKUP_FINAL_DIR" ]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "File with destination to back-up does not exist. Exiting..."
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" ""
    exit 1
else
    VAR_BACKUP_FINAL_DIR=$(cat "$VAR_BACKUP_FINAL_DIR")
fi

if ! [ -f "$VAR_SCRIPT_CONFIG_FILE" ]; then
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "File with directories to back-up does not exist. Exiting..."
    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" ""
    exit 1
else
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Loading default configuration:"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "VAR_BACKUP_TEMP_DIR        : $VAR_BACKUP_TEMP_DIR"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "VAR_BACKUP_FINAL_DIR       : $VAR_BACKUP_FINAL_DIR"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "VAR_BACKUP_MAX_BACKUPS     : $VAR_BACKUP_MAX_BACKUPS"
    #echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "VAR_BACKUP_MAX_HASH_CHECKS : $VAR_BACKUP_MAX_HASH_CHECKS"
fi



createBackUp_PreCheck(){
    # $1 = directory to back-up
    # $2 = temp file path
    # $3 = final file path

    if [ -e "$2" ]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Temporary back-up file with this name already exists: '$2'. Skipping..."
        echoInfo
        return 99
    fi

    if [ -e "$3" ]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Final back-up file with this name already exists: '$3'. Skipping..."
        echoInfo
        return 99
    fi

    return 0

}



CreateBackUp(){
    # $1 = directory to back-up
    # $2 = temp file path
    # $3 = final file path

    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  - Creating back-up for '$1' in 5 seconds..."

    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Directory to backup         - $1"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Temporary File Path         - $2"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Final Destination File Path - $3"
    
    #sleep 5

    "$(which tar)" --use-compress-program=zstd -cvf "$2" "$1" &> /dev/null

    return 0

}



MoveBackUp(){
    # $1 = directory to back-up
    # $2 = temp file path
    # $3 = final file path

    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  - Moving back-up for '$1' in 5 seconds..."

    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Directory to backup         - $1"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Temporary File Path         - $2"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Final Destination File Path - $3"
    
    #sleep 5

    "$(which cp)" "$2" "$3"

    if [ ! -e "$2" ] || [ ! -e "$3" ]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    One of two back-up files not existing for '$1'. Aborting this back-up..."
        echoInfo
        return 99
    fi

    if [ $(shasum "$2" | awk '{print $1}') == $(shasum "$3" | awk '{print $1}') ]; then
        echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    SHASUM OK"
        "$(which rm)" "$2"
    else
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Checksum mismatch for '$1'. Aborting this back-up..."
        echoInfo
        return 99
    fi

    return 0

}



RemoveOldBackUps(){
    # $1 = directory to back-up
    # $2 = temp file path
    # $3 = final file path

    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  - Removing old back-up(s) for '$1' in 5 seconds..."

    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Directory to backup         - $1"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Temporary File Path         - $2"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Final Destination File Path - $3"
    
    #sleep 5

    while [ $(tree "$VAR_BACKUP_FINAL_DIR$1" | grep -c "$VAR_BACKUP_FILE_TYPE") -gt $VAR_BACKUP_MAX_BACKUPS ];do
        for var_directory in "$VAR_BACKUP_FINAL_DIR$1"/*; do
            for var_file in "$var_directory"/*; do
                if [ $(tree "$var_directory" | grep -c "$VAR_BACKUP_FILE_TYPE") == 0 ]; then
                    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Removing empty directory '$var_directory'..."
                    "$(which rm)" -rf "$var_directory"
                    break 2
                fi
                echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Removing back-up file '$var_file'..."
                "$(which rm)" "$var_file"
                break 2
            done
            break 1
        done
    done



}



while IFS= read -r var_directory_line; do

   # Skip empty line
    if [[ "$var_directory_line" = "" ]]; then
        continue
    fi

    # Print a message with the current line
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Processing Line : $var_directory_line"

    # Use sed to remove any leading spaces or other unwanted characters
    var_backup_directory=$(echo "$var_directory_line" | sed "s/\"//g; s/\'//g")
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "BackUp Dir : $var_backup_directory"

    if ! [ -d "$var_backup_directory" ]; then
        echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Directory '$var_backup_directory' does not exist. Skipping..."
        echoInfo
        continue
    fi

    var_datetime_yearmonthday=$(date +"%Y%m%d")
    var_backup_file_dir_temp="$VAR_BACKUP_TEMP_DIR$var_backup_directory/$var_datetime_yearmonthday"
    var_backup_file_dir_final="$VAR_BACKUP_FINAL_DIR$var_backup_directory/$var_datetime_yearmonthday"

    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Creating temporary directory '$var_backup_file_dir_temp'..."
    "$(which mkdir)" -p "$var_backup_file_dir_temp"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Creating final directory '$var_backup_file_dir_final'..."
    "$(which mkdir)" -p "$var_backup_file_dir_final"

    var_datetime_hourminute=$(date +"%H%M")
    var_backup_file_temp_fullpath="$var_backup_file_dir_temp/$var_datetime_hourminute.$VAR_BACKUP_FILE_TYPE"
    var_backup_file_final_fullpath="$var_backup_file_dir_final/$var_datetime_hourminute.$VAR_BACKUP_FILE_TYPE"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Temporary Destination : $var_backup_file_temp_fullpath"
    echoDebug "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Final Destination     : $var_backup_file_final_fullpath"

    # Create back-up pre check

    if ! createBackUp_PreCheck "$var_backup_directory" "$var_backup_file_temp_fullpath" "$var_backup_file_final_fullpath"; then
        continue
    fi

    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Ready to create back-up for '$var_directory_line'!"

    # Create back-up
    if ! CreateBackUp "$var_backup_directory" "$var_backup_file_temp_fullpath" "$var_backup_file_final_fullpath"; then
        continue
    fi

    # Move back-up
    if ! MoveBackUp "$var_backup_directory" "$var_backup_file_temp_fullpath" "$var_backup_file_final_fullpath"; then
        continue
    fi
    # Remove old back-up(s)
    if ! RemoveOldBackUps "$var_backup_directory" "$var_backup_file_temp_fullpath" "$var_backup_file_final_fullpath"; then
        continue
    fi

    echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Done!"

    echoInfo

done < "$VAR_SCRIPT_CONFIG_FILE"

wait
echoInfo "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Script finished successfully!"