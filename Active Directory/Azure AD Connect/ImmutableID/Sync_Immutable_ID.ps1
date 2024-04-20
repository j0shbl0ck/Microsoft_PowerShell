⚠️ THIS SCRIPT IS UNDER DEVELOPMENT AND NOT READY FOR USE. ⚠️ 

.LINK
https://poweraddict.net/get-immutable-id-of-ad-object/
https://messageops.com/step-by-step-guide-to-hard-match-a-user-on-office-365-or-azure-ad/
.NOTES
Ensure MSOnline module is installed.

# Cloud user has no source anchor attached to it.
# AD user does have a source anchor attached to it.

# Convert ObjectGUID (on-premise object) to ImmutableID (in cloud object)
Clear-Host
Import-Module ActiveDirectory  
$UserSamAccount = Read-Host "Provide SamAccountName of a user"
  
$User = Get-ADuser $UserSamAccount -Properties ObjectGUID
  
$ImmutableID = [system.convert]::ToBase64String(([GUID]($User.ObjectGUID)).tobytearray())
  
Write-Host "ImmutableID for user $UserSamAccount is:" -ForegroundColor Cyan
$ImmutableID

Connect-MsolService
$AzureUser = Read-Host "Provide Azure AD user name"
Get-MsolUser -UserPrincipalName $AzureUser | FL immutableId

