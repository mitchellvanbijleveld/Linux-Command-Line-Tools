echo "Please select on of the following options:"
PrintDirectoryContent "FILES" "$VAR_BIN_INSTALL_DIR/Daemon/Examples"
if [[ ${#DirectoryContent[@]} -eq 0 ]]; then
    echo "  No example daemons are available to install."
fi
echo
echo "Available choices:"; AvailableChoices_Reset
if [[ ${#DirectoryContent[@]} -gt 0 ]]; then
    AvailableChoices_Add "1-${#DirectoryContent[@]}" "Daemon to install"
fi
AvailableChoices_Add "B" "Back"
AvailableChoices_Add "Q" "Quit Interactive Shell"
echo
PrintUserChoiceQuestion

if [[ $UserInput -ge 1 ]] && [[ $UserInput -le ${#DirectoryContent[@]} ]]; then
    StartUtilityScript $(basename ${DirectoryContent[$((UserInput - 1))]})
elif [[ $(echo $UserInput | tr '[:lower:]' '[:upper:]')  == "B" ]]; then
    PrintMenu_Utility $VAR_UTILITY
elif [[ $(echo $UserInput | tr '[:lower:]' '[:upper:]')  == "Q" ]]; then
    echo "Quiting Interactive Shell..."
    echo
    exit 0
else
    echo "Can't handle this option."
    echo
    exit 1
fi