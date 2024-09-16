read -p "Please type the domain name of the alias to be created: " DomainName
read -p "Please type the email address of the alias being added to: " EmailAddress
echo
read -p "Alias '$DomainName' will be added to email address '$EmailAddress'. Is this correct? Please type 'y' or 'yes': " UserInput

if [[ $(echo $UserInput | tr '[:lower:]' '[:upper:]')  == "Y" ]] || [[ $(echo $UserInput | tr '[:lower:]' '[:upper:]')  == "YES" ]]; then
   StartUtilityScript "$DomainName" "$EmailAddress"
else
   echo "OK, not doing anything. Exiting..."
   echo
   exit 0
fi