<#
.SYNOPSIS
    This imports users via CSV into a mail-enabled security group.
.NOTES
    Author: Josh Block
    Date: 01.03.23
    Type: Public
    Version: 1.0.8
.LINK
    https://github.com/j0shbl0ck
    https://social.technet.microsoft.com/wiki/contents/articles/54249.365-add-members-in-distribution-list-using-powershell-and-csv-list-file.aspx
#>

Clear-Host

# Ask user for Global/Exchange Admin UPN
$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)' 

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName $gadmin | Clear-Host

https://adamtheautomator.com/powershell-check-if-file-exists/

# Ask user for file path to .CSV
Write-Host -ForegroundColor Yellow 'Please enter the path (no quotes around path) to the .CSV file:'
# Check if file exists if not ask user to try again
do {
    $filePath = Read-Host
    $validatefile = Test-Path -Path $filePath
    if ($validation -eq $False){
        Write-Host -ForegroundColor Red 'File does not exist. Please try again.'
    }
} until ($validatefile -eq $True)

# Import .CSV file
Write-Host -ForegroundColor Yellow 'Importing .CSV file...'
Write-Host -ForegroundColor Green 'Import complete.'
Write-host ""

# Set Distribution List CSV variable
$users = Import-CSV $filePath

# get headers from CSV file
$headers = $users | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

# check if the CSV file has the correct headers
if ($headers -notcontains 'Email') {
    Write-Warning 'The CSV file does not contain the correct headers. Please correct headers and try again.'
    Write-Warning 'The headers should be: Name,Email'
    Write-host ""
    Start-Sleep -Seconds 5
}
else {
    # Ask user if they want to create a distribution list or already have one
    while ($choice -ne 'y' -and $choice -ne 'n') 
    {
        $choice = Read-Host -Prompt 'Do you want to create the Mail-enabled Security group? (Y/N)'
        if ($choice -eq 'y') {
            # ask user for the name of the distribution list
            Write-Host -ForegroundColor Yellow "`nWhat is the name of the Mail-enabled Security group?"
            $dlname = Read-Host
            # ask user for the email address of the distribution list
            Write-Host -ForegroundColor Yellow "`nWhat is the email address of the Mail-enabled Security group?"
            $dlemail = Read-Host
            # create the distribution list
            New-DistributionGroup -Name $dlname -PrimarySmtpAddress $dlemail -Type "Security"
            Write-Host -ForegroundColor Green 'Mail-enabled Security group: ' $dlname ' created.'
            Write-host ""
            # Perform the create distrubution list operation
            Write-Host -ForegroundColor Yellow 'Adding users to Mail-enabled Security group:' $dlname
            ForEach ($user in $users){
                Add-DistributionGroupMember -Identity "$dlname" -Member $user.Email
                Write-Host -ForegroundColor Green "User:" $user.Email  "added.`n"
            }
        } elseif ($choice -eq 'n') {
            # get the email of the distribution list
            Write-Host -ForegroundColor Yellow "`nWhat is the name of the Mail-enabled Security group?"
            $dlemail2 = Read-Host
            # Perform the create distrubution list operation
            Write-Host -ForegroundColor Yellow 'Adding users to Mail-enabled Security group:' $dlname
            ForEach ($user in $users){
                Add-DistributionGroupMember -Identity $dlemail2 -Member $user.Email
                Write-Host -ForegroundColor Green "User:" $user.Email "added.`n"
            }
        } else {
            Write-Host -ForegroundColor Red "Invalid input. Please type 'y' or 'n'"
        }
    }
}

# Disconnect from Exchange Online
Write-Host -ForegroundColor Yellow "`nDisconnecting from Exchange Online..."
Disconnect-ExchangeOnline -Confirm:$false
Write-Host -ForegroundColor Green 'Complete.'
Write-host ""