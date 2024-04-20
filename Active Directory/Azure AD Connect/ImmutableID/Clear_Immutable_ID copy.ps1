<#
.SYNOPSIS
    This pulls in all users in Etra ID and sets their ImmutableID attribute to $null
.NOTES
    Author: Josh Block
    Date: 04.19.24
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://learn.microsoft.com/en-us/answers/questions/1333250/how-to-set-users-onpremisesimmutableid-field-to-nu
    https://techcommunity.microsoft.com/t5/windows-powershell/get-mguser-how-to-get-more-than-100-users-when-looping-through/m-p/3814393
#>

# Check for if Microsoft Graph module is downloaded

# Clear any Microsoft Graph connections then prompting for sign-in
#Disconnect-MgGraph -ErrorAction SilentlyContinue

# Connect to Microsoft Graph module
#Connect-MgGraph -Scopes "User.ReadWrite.All"

# Pull all users within tenant
$entrausers = Get-Mguser -ConsistencyLevel:eventual -Count:userCount -Filter "endsWith(UserPrincipalName, '@allstate75.com')" | Select DisplayName,UserPrincipalName,Id


ForEach ($entrauser in $entrausers){
    
    # Get User's DisplayName
    Get-MgUser -UserId $entrauser.Id -Property DisplayName | select DisplayName
    $upn = $entrauser.UserPrincipalName;
    # Clear the ImmutableID value for user
    Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/${upn}" -Body @{OnPremisesImmutableId = $null}
    # Get User's Immutable ID value
    Get-Mguser -UserId $entrauser.Id -Property onPremisesImmutableId | select onpremisesimmutableid

}

# Disconnect from Microsoft Graph module
#Disconnect-MgGraph