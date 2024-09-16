echo "Please select on of the following options:"
echo "  [ 1] All"
echo "  [ 2] Examples"
echo "  [ 3] Installed"
echo "  [ 4] Running"
echo
echo "Available choices:"; AvailableChoices_Reset
AvailableChoices_Add "1-4" "Optons listed aboce"
AvailableChoices_Add "B" "Back"
AvailableChoices_Add "Q" "Quit Interactive Shell"
echo
PrintUserChoiceQuestion

if [[ $UserInput -ge 1 ]] && [[ $UserInput -le 4 ]]; then
    case $UserInput in
    1) StartUtilityScript "ALL";;
    2) StartUtilityScript "EXAMPLES";;
    3) StartUtilityScript "INSTALLED";;
    4) StartUtilityScript "RUNNING";;
    esac
elif [[ $(echo $UserInput | tr '[:lower:]' '[:upper:]')  == "B" ]]; then
    PrintMenu_Utility $VAR_UTILITY
elif [[ $(echo $UserInput | tr '[:lower:]' '[:upper:]')  == "Q" ]]; then
    echo "Quiting Interactive Shell..."
    echo
    exit 0
else
    echo "I don't know how to react to your input '$UserInput'..."
    echo
    exit 1
fi