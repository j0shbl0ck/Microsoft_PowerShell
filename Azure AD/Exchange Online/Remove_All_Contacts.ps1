
https://github.com/microsoftgraph/microsoft-graph-docs-contrib/blob/main/api-reference/v1.0/api/contact-delete.md

# Check for if Microsoft Graph module is downloaded
# Check for if Microsoft Graph module is downloaded
Function Block-Script {
}

# Clear any Microsoft Graph connections then prompting for sign-in
#Disconnect-MgGraph -ErrorAction SilentlyContinue

# Connect to Microsoft Graph module
#Connect-MgGraph -Scopes "User.ReadWrite.All"

# Pull all users within tenant
$entrausers = Get-Mguser -ConsistencyLevel:eventual -Count:userCount -Filter "endsWith(UserPrincipalName, '@company75.com')" | Select DisplayName,UserPrincipalName,Id,OnPremisesImmutableId

GET /contacts?$filter=emailAddresses/any(a:a/address eq 'someone@somplace.com')
DELETE /contacts/{id}

https://learn.microsoft.com/en-us/graph/api/resources/contact?view=graph-rest-1.0
https://learn.microsoft.com/en-us/graph/api/resources/contactfolder?view=graph-rest-1.0

another user has shared a contact folder with that user, or, has given delegated access to that user


This morning, before diving into scripting, I checked Microsoft's servers to see what categories/folders were associated with your contacts.  Interestingly, the servers only reflected "company Employees Copy" and "company Contacts Copy," which is exactly what you see in Legacy Outlook. This suggests a bug in the new Outlook that prevents it from modifying category information and contact changes after the initial sync to reflect the same.

My initial plan was to identify and remove all other categories from contacts, but since they're not even visible, we're at a dead end. 

https://graph.microsoft.com/v1.0/users/user@test.com/contactFolders/"{contactFolders id}="/contacts?$filter=emailAddresses/any(a:a/address eq 'user@test.com')



https://graph.microsoft.com/v1.0/users/user@test.com/contactFolders/"{contactFolders id}"/contacts?$filter=categories/any(c:c eq 'Company Contacts Copy')

# Get the UPN of the user
$getuserId = Write-Host "Enter User Principal Name"

# Insert $getuserId to get UPN variable
$userId = Get-Mguser -ConsistencyLevel:eventual -Count:userCount -Filter "endsWith(UserPrincipalName, '@test.com')" | Select UserPrincipalName,

# Collect array of contacts from user
$contacts = Get-MgUserContact -UserId $userId < if pulling from the user mailbox
$contacts = Get-MgUserContactFolderContact -UserId $userId -ContactFolderId $contactFolderId -ContactId $contactId < if pulling from a specified contact folder
$contactfolders = Get-MgUserContactFolder -UserId $userId < gets list of contact folders

ForEach ($contact in $contacts){
    
    # Get Contact Id
    $cis = $contact.id

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

    ForEach ($ci in $cis){

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