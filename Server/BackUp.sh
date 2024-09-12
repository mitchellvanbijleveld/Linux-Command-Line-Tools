#!/bin/bash
VAR_UTILITY="Server"
VAR_UTILITY_SCRIPT="BackUp"
VAR_UTILITY_SCRIPT_VERSION="2024.XX.XX-XXXX"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="cp echo PrintMessage sha512sum sleep tar tree" # msmtp

if [[ "$@" == *"--verbose"* ]]; then
    VAR_SCRIPT_VERBOSE=1
else
    VAR_SCRIPT_VERBOSE=0
fi

if [[ $(whoami) != "root" ]]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Only the 'root' user should execute this backup utility script. Exiting..."
    PrintMessage
    exit 1
fi

VAR_SCRIPT_CONFIG_FILE="$VAR_UTILITY_SCRIPT_CONFIG_DIR/directories"
VAR_BACKUP_FINAL_DIR="$VAR_UTILITY_SCRIPT_CONFIG_DIR/destination"
VAR_BACKUP_MAX_BACKUPS=4
#VAR_BACKUP_MAX_HASH_CHECKS=60
VAR_BACKUP_FILE_TYPE="tar.zst"

if ! [ -f "$VAR_BACKUP_FINAL_DIR" ]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "File with destination to back-up does not exist. Exiting..."
    PrintMessage "INFO" 
    exit 1
else
    VAR_BACKUP_FINAL_DIR=$(cat "$VAR_BACKUP_FINAL_DIR")
fi

if ! [ -f "$VAR_SCRIPT_CONFIG_FILE" ]; then
    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "File with directories to back-up does not exist. Exiting..."
    PrintMessage
    exit 1
else
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Loading default configuration:"
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "VAR_UTILITY_SCRIPT_TEMP_DIR : $VAR_UTILITY_SCRIPT_TEMP_DIR"
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "VAR_BACKUP_FINAL_DIR        : $VAR_BACKUP_FINAL_DIR"
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "VAR_BACKUP_MAX_BACKUPS      : $VAR_BACKUP_MAX_BACKUPS"
    #PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "VAR_BACKUP_MAX_HASH_CHECKS : $VAR_BACKUP_MAX_HASH_CHECKS"
fi



createBackUp_PreCheck(){
    # $1 = directory to back-up
    # $2 = temp file path
    # $3 = final file path

    if [ -e "$2" ]; then
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Temporary back-up file with this name already exists: '$2'. Skipping..."
        PrintMessage
        return 99
    fi

    if [ -e "$3" ]; then
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Final back-up file with this name already exists: '$3'. Skipping..."
        PrintMessage
        return 99
    fi

    return 0

}



CreateBackUp(){
    # $1 = directory to back-up
    # $2 = temp file path
    # $3 = final file path

    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  - Creating back-up for '$1' in 5 seconds..."

    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Directory to backup         - $1"
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Temporary File Path         - $2"
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Final Destination File Path - $3"
    
    #sleep 5

    if [ $VAR_SCRIPT_VERBOSE -eq 1 ]; then
        echo 'verbose'
        "$(which tar)" --use-compress-program=zstd -cvf "$2" "$1"
    else
        "$(which tar)" --use-compress-program=zstd -cvf "$2" "$1" &> /dev/null
    fi

    if [ $? -eq 0 ]; then
        return 0
    else
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  - Error while compressing back-up for '$1'. Process exited with exit code $?"
        return 99
    fi

}



MoveBackUp(){
    # $1 = directory to back-up
    # $2 = temp file path
    # $3 = final file path

    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  - Moving back-up for '$1' in 5 seconds..."

    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Directory to backup         - $1"
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Temporary File Path         - $2"
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Final Destination File Path - $3"
    
    #sleep 5

    "$(which cp)" "$2" "$3"

    if [ ! -e "$2" ] || [ ! -e "$3" ]; then
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    One of two back-up files not existing for '$1'. Aborting this back-up..."
        PrintMessage
        return 99
    fi

    if [ $(sha512sum "$2" | awk '{print $1}') == $(sha512sum "$3" | awk '{print $1}') ]; then
        PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    sha512sum OK"
        "$(which rm)" "$2"
    else
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Checksum mismatch for '$1'. Aborting this back-up..."
        PrintMessage
        return 99
    fi

    return 0

}



RemoveOldBackUps(){
    # $1 = directory to back-up
    # $2 = temp file path
    # $3 = final file path

    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "  - Removing old back-up(s) for '$1' in 5 seconds..."

    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Directory to backup         - $1"
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Temporary File Path         - $2"
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Final Destination File Path - $3"
    
    #sleep 5

    while [ $(tree "$VAR_BACKUP_FINAL_DIR$1" | grep -c "$VAR_BACKUP_FILE_TYPE") -gt $VAR_BACKUP_MAX_BACKUPS ];do
        for var_directory in "$VAR_BACKUP_FINAL_DIR$1"/*; do
            for var_file in "$var_directory"/*; do
                if [ $(tree "$var_directory" | grep -c "$VAR_BACKUP_FILE_TYPE") == 0 ]; then
                    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Removing empty directory '$var_directory'..."
                    "$(which rm)" -rf "$var_directory"
                    break 2
                fi
                PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "    Removing back-up file '$var_file'..."
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
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Processing Line : $var_directory_line"

    # Use sed to remove any leading spaces or other unwanted characters
    var_backup_directory=$(echo "$var_directory_line" | sed "s/\"//g; s/\'//g")
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "BackUp Dir : $var_backup_directory"

    if ! [ -d "$var_backup_directory" ]; then
        PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Directory '$var_backup_directory' does not exist. Skipping..."
        PrintMessage
        continue
    fi

    var_datetime_yearmonthday=$(date +"%Y%m%d")
    var_backup_file_dir_temp="$VAR_UTILITY_SCRIPT_TEMP_DIR$var_backup_directory/$var_datetime_yearmonthday"
    var_backup_file_dir_final="$VAR_BACKUP_FINAL_DIR$var_backup_directory/$var_datetime_yearmonthday"

    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Creating temporary directory '$var_backup_file_dir_temp'..."
    "$(which mkdir)" -p "$var_backup_file_dir_temp"
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Creating final directory '$var_backup_file_dir_final'..."
    "$(which mkdir)" -p "$var_backup_file_dir_final"

    var_datetime_hourminute=$(date +"%H%M")
    var_backup_file_temp_fullpath="$var_backup_file_dir_temp/$var_datetime_hourminute.$VAR_BACKUP_FILE_TYPE"
    var_backup_file_final_fullpath="$var_backup_file_dir_final/$var_datetime_hourminute.$VAR_BACKUP_FILE_TYPE"
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Temporary Destination : $var_backup_file_temp_fullpath"
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Final Destination     : $var_backup_file_final_fullpath"

    # Create back-up pre check

    if ! createBackUp_PreCheck "$var_backup_directory" "$var_backup_file_temp_fullpath" "$var_backup_file_final_fullpath"; then
        continue
    fi

    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Ready to create back-up for '$var_directory_line'!"

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

    PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Done!"

    PrintMessage

done < "$VAR_SCRIPT_CONFIG_FILE"

wait
PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Script finished successfully!"