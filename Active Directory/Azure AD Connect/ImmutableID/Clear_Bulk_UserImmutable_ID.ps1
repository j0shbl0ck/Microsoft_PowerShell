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
# Check for if Microsoft Graph module is downloaded
Function Block-Script {
}

# Clear any Microsoft Graph connections then prompting for sign-in
#Disconnect-MgGraph -ErrorAction SilentlyContinue

# Connect to Microsoft Graph module
#Connect-MgGraph -Scopes "User.ReadWrite.All"

# Pull all users within tenant
$entrausers = Get-Mguser -ConsistencyLevel:eventual -Count:userCount -Filter "endsWith(UserPrincipalName, '@company.com')" | Select DisplayName,UserPrincipalName,Id,OnPremisesImmutableId


ForEach ($entrauser in $entrausers){
    
    # Get User's DisplayName
    $dp = $entrauser.DisplayName

    # Get user's UPN
    $upn = $entrauser.UserPrincipalName
    
    # Get user's ImmutableID
    $iis = Get-Mguser -UserId $entrauser.id -Property onPremisesImmutableId | select onpremisesimmutableid
    $opii = $iis.OnPremisesImmutableId
        if ($opii -eq $null) {
            Write-Host -ForegroundColor Magenta "Current ImmutableID for ${dp}: null"
        } else {
            Write-Host -ForegroundColor Yellow "Current ImmutableID for ${dp}: ${opii}"
        }

    
    # Display Current ImmutableID for user
    #Write-Host -ForegroundColor Yellow "Current ImmutableID for ${dp}: ${opii}"

    ForEach ($ii in $iis){

    # Clear the ImmutableID value for user
    Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/${upn}" -Body @{OnPremisesImmutableId = $null}
    
    # Display Updated ImmutableID for user
    $iis2 = Get-Mguser -UserId $entrauser.id -Property onPremisesImmutableId | select onpremisesimmutableid
    $opii2 = $iis2.OnPremisesImmutableId
        if ($opii2 -eq $null) {
            Write-Host -ForegroundColor Green "Current ImmutableID for ${dp}: null"
        } else {
            Write-Host -ForegroundColor Red "Current ImmutableID for ${dp}: ${opii2}"
        }
    Write-Host ""

    }

}

# Disconnect from Microsoft Graph module
Disconnect-MgGraph