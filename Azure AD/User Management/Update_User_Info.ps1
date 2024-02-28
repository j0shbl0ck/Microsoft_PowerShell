<#
.SYNOPSIS
    This creates imports contacts via CSV.
.NOTES
    Author: Josh Block
    Date: 08.18.22
    Type: Public
    Version: 1.0.7
.LINK
    https://github.com/j0shbl0ck
    https://m365scripts.com/exchange-online/bulk-import-contacts-office-365-powershell/#:~:text=Multiple%20contacts%20can%20be%20added,file%20with%20the%20contact%20info.
    https://docs.microsoft.com/en-us/microsoft-365/compliance/bulk-import-external-contacts?view=o365-worldwide
    https://o365info.com/update-azure-ad-users/
#>

Clear-Host

# Connect to Microsoft Graph via Azure AD with Global/Exchange admin.
Write-Host -ForegroundColor Cyan 'Connecting to Microsoft Graph...'
Connect-MgGraph -Scopes User.ReadWrite.All
Write-host ""

# Ask user for file path to .CSV
Write-Host -ForegroundColor Cyan 'Please enter the path (no quotes around path) to the .CSV file:'
# Check if file exists if not ask user to try again
do {
    $filePath = Read-Host
    $validatefile = Test-Path -Path $filePath
    if ($validation -eq $False){
        Write-Host -ForegroundColor Red 'File does not exist. Please try again.'
    }
} until ($validatefile -eq $True)

# Import .CSV file
$users = Import-CSV $filePath
Write-Host -ForegroundColor Yellow 'Importing .CSV file...'
Write-Host -ForegroundColor Green 'Import complete.'
Write-host ""

# Go through each user in the CSV and update the job title
foreach ($user in $users) {
    $userPrincipalName = $user.emailAddress
    $officeLocation = $user.officeLocation
    $employeeType = $user.employmentType



    # Check if the user exists
    $existingUser = Get-MgBetaUser -UserId $userPrincipalName -ErrorAction SilentlyContinue

    if ($existingUser) {
        # Check if the existing job title matches the new value
        if ($existingUser.JobTitle -eq $officeLocation) {
            # Job title already set with the same value
            Write-Host "User '$userPrincipalName' already has office location to '$officeLocation' and employee type to '$employeeType' ." -ForegroundColor Cyan
        }
        else {
            # Update the job title
            Update-MgUser -UserId $userPrincipalName -officeLocation $officeLocation -employeeType $employeeType
            Write-Host "User '$userPrincipalName' updated office location to '$officeLocation' and employee type to '$employeeType' successfully." -ForegroundColor Green
        }
    }
    else {
        # User not found
        Write-Host "User '$userPrincipalName' not found." -ForegroundColor Red
    }
}

#Import-CSV blabla.csv | % { Update-MgUser -UserId $_.UserPrincipalName -Department $_.Department }
