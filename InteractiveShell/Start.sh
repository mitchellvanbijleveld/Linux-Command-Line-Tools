#!/bin/bash
VAR_UTILITY="InteractiveShell"
VAR_UTILITY_SCRIPT="Start"
VAR_UTILITY_SCRIPT_VERSION="2024.09.16-2222"
VAR_SCRIPT_REQUIRED_COMMAND_LINE_TOOLS="echo PrintMessage"

PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT"
PrintMessage "INFO" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT"

####################################################################################################
####################################################################################################
# GLOBAL MENU ITEMS
####################################################################################################
PrintMenuHeader(){
    $(which clear)
    echo "==========================================================================="
    echo "#                                                 Version $VAR_UTILITY_SCRIPT_VERSION #"
    echo "#                                                                         #"
    echo "# Interactive Shell - Linux Command Line Tools                            #"
    echo "#                                                                         #"
    echo "#                                           © 2024 Mitchell van Bijleveld #"
    echo "==========================================================================="
    echo ""
}
export -f PrintMenuHeader

PrintUserChoiceQuestion(){
    echo -n "Please make a choice "; read -p "[ $AvailableChoicesString ]: " UserInput
    if [[ $UserInput == "" ]]; then
        while [[ $UserInput == "" ]]; do
            echo -n "You did not give a choice. Please make a choice "; read -p "[ $AvailableChoicesString ]: " UserInput
        done
    fi
}
export -f PrintUserChoiceQuestion
####################################################################################################
# GLOBAL MENU ITEMS
####################################################################################################
####################################################################################################





####################################################################################################
####################################################################################################
# FUNCTIONS
####################################################################################################
PrintDirectoryContent(){ # NOT USED AT THE MOMENT! MIGHT BE USEFUL IN THE FUTURE
    # $1 = DIRS | FILES
    # $2 = Base Directory
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Listing contents of directory '$2/'..."
    DirectoryContent=()
    for FoundItem in "$2/"*; do
        FoundItemBaseName=$(basename $FoundItem)
        if [[ $1 == "DIRS" ]] && [[ -d $FoundItem ]]; then
            echo "  [$(printf "%2d\n" "$((${#DirectoryContent[@]} + 1))")] $FoundItemBaseName"
        elif [[ $1 == "FILES" ]] && [[ -f $FoundItem ]]; then
            echo "  [$(printf "%2d\n" "$((${#DirectoryContent[@]} + 1))")] $(echo $FoundItemBaseName | sed 's/.sh$//')"
        else
            continue
        fi
        DirectoryContent+=("$FoundItem")
    done
}
export -f PrintDirectoryContent

PrintAvailableUtilities(){
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Listing contents of directory '$VAR_BIN_INSTALL_DIR/'..."
    AvailableUtilities=()
    for DirectoryContent in "$VAR_BIN_INSTALL_DIR/"*; do
        if [[ -d $DirectoryContent ]] && [[ $(basename $DirectoryContent) != "InteractiveShell" ]]; then
            AvailableUtilities+=("$DirectoryContent")
            echo "  [$(printf '%2d\n' ${#AvailableUtilities[@]})] $(basename $DirectoryContent)"
        fi
    done
}
export -f PrintAvailableUtilities

PrintAvailableUtilityScripts(){
    PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Listing contents of directory '$VAR_BIN_INSTALL_DIR/$1/'..."
    AvailableUtilityScripts=()
    for DirectoryContent in "$VAR_BIN_INSTALL_DIR/$1/"*; do
        if [[ -f $DirectoryContent ]] && [[ $DirectoryContent == *".sh" ]]; then
            AvailableUtilityScripts+=("$DirectoryContent")
            echo "  [$(printf '%2d\n' ${#AvailableUtilityScripts[@]})] $(basename $DirectoryContent | sed 's/.sh$//')"
        fi
    done
}
export -f PrintAvailableUtilityScripts

# Available Choices
AvailableChoices_Reset(){
    AvailableChoicesString=""
    InteractiveMenu_Option_Keys=()
    InteractiveMenu_Option_Descriptions=()
    InteractiveMenu_Option_LongDescriptions=()
}
export -f AvailableChoices_Reset

AvailableChoices_Add(){
    # $1 = Option Keys
    # $2 = Option Descriptions
    # $3 = Option Long Descriptions
    InteractiveMenu_Option_Keys+=("$1")
    InteractiveMenu_Option_Descriptions+=("$2")
    InteractiveMenu_Option_LongDescriptions+=("$3")
    AvailableChoicesString="$AvailableChoicesString | $1"
    echo "  - $(printf '%-3s' "$1") : $2"
    AvailableChoicesString=$(echo $AvailableChoicesString | sed 's/^| //;')
}
export -f AvailableChoices_Add

StartUtilityScript() {
    ScriptArguments=$@
    PrintMessage "DEBUG" "InteractiveShell/$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Starting bin '$VAR_BIN_INSTALL_DIR/mitchellvanbijleveld'..."
    PrintMessage "DEBUG" "InteractiveShell/$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Starting Utility '$VAR_UTILITY' Script '$VAR_UTILITY_SCRIPT' with arguments '$ScriptArguments'..."
    "$VAR_BIN_INSTALL_DIR/mitchellvanbijleveld" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" $@
}
export -f StartUtilityScript
####################################################################################################
# FUNCTIONS
####################################################################################################
####################################################################################################





####################################################################################################
####################################################################################################
# MENUS
##########.#########################################################################.###############

PrintMenu_Main(){
    PrintMenuHeader
    echo "Welcome to the Interactive Shell for Linux Command Line Tools!"
    echo ""
    echo "This menu helps you navigating through all available utility. After"
    echo "selecting the utility, you will be able to start the utility script."
    echo ""
    echo "The following utilities are available:"
    PrintAvailableUtilities
    echo
    echo "Available choices:"; AvailableChoices_Reset
    AvailableChoices_Add "1-${#AvailableUtilities[@]}" "Utility from the list"
    AvailableChoices_Add "Q" "Quit Interactive Shell"
    echo
    PrintUserChoiceQuestion

    if [[ $UserInput -ge 1 ]] && [[ $UserInput -le ${#AvailableUtilities[@]} ]]; then
        echo "You selected a number! The number is $UserInput"
        echo "The Utility belong here is"  ${AvailableUtilities[$((UserInput - 1))]}
        ls "${AvailableUtilities[$((UserInput - 1))]}"
        PrintMenu_Utility $(basename ${AvailableUtilities[$((UserInput - 1))]})
    elif [[ $(echo $UserInput | tr '[:lower:]' '[:upper:]')  == "Q" ]]; then
        echo "Quiting Interactive Shell..."
        echo
        exit 0
    else
        echo "Can't handle this option."
        echo
        exit 1
    fi
}
export -f PrintMenu_Main

PrintMenu_Utility(){
    PrintMenuHeader
    echo "This is the utility menu for $1."
    echo
    #echo "This menu helps you navigating through all available utility. After"
    #echo "selecting the utility, you will be able to start the utility script."
    #echo ""
    echo "The following utility scripts are available:"
    PrintAvailableUtilityScripts $1
    echo
    echo "Available choices:"; AvailableChoices_Reset
    AvailableChoices_Add "1-${#AvailableUtilityScripts[@]}" "Utility Script from the list"
    AvailableChoices_Add "B" "Back"
    AvailableChoices_Add "Q" "Quit Interactive Shell"
    echo
    PrintUserChoiceQuestion

    if [[ $UserInput -ge 1 ]] && [[ $UserInput -le ${#AvailableUtilityScripts[@]} ]]; then
        UtilityScriptBaseName="$(basename ${AvailableUtilityScripts[$((UserInput - 1))]})"
        if [[ -f "$VAR_BIN_INSTALL_DIR/InteractiveShell/$1/$UtilityScriptBaseName" ]]; then
            PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Starting Interactive Shell for Utility '$1' Script '$(echo $UtilityScriptBaseName | sed 's/.sh$//')'..."
            VAR_UTILITY=$1
            VAR_UTILITY_SCRIPT=$(echo $UtilityScriptBaseName | sed 's/.sh$//')
            PrintMenu_UtilityScript
        else
            PrintMessage "DEBUG" "$VAR_UTILITY" "$VAR_UTILITY_SCRIPT" "Starting Utility '$1' Script '$(echo $UtilityScriptBaseName | sed 's/.sh$//')'..."
            "$VAR_BIN_INSTALL_DIR/mitchellvanbijleveld" "$1" "$(echo $UtilityScriptBaseName | sed 's/.sh$//')"
        fi
    elif [[ $(echo $UserInput | tr '[:lower:]' '[:upper:]')  == "B" ]]; then
        PrintMenu_Main
    elif [[ $(echo $UserInput | tr '[:lower:]' '[:upper:]')  == "Q" ]]; then
        echo "Quiting Interactive Shell..."
        echo
        exit 0
    else
        echo "I don't know how to react to your input '$UserInput'..."
        echo
        exit 1
    fi
}
export -f PrintMenu_Utility

PrintMenu_UtilityScript(){
    PrintMenuHeader
    echo "Welcome to the Interactive Shell for $VAR_UTILITY/$VAR_UTILITY_SCRIPT!"
    echo
    "$(which bash)" "$VAR_BIN_INSTALL_DIR/InteractiveShell/$VAR_UTILITY/$UtilityScriptBaseName"
}
export -f PrintMenu_UtilityScript
####################################################################################################
# MENUS
####################################################################################################
####################################################################################################





####################################################################################################
####################################################################################################
# MAIN LOOP
####################################################################################################
echo "Starting Interactive Shell..."
#sleep 1
PrintMenu_Main
####################################################################################################
# MAIN LOOP
####################################################################################################
####################################################################################################