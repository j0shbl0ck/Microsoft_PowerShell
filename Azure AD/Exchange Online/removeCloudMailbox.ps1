<#
.SYNOPSIS
    This script removes all cloud mailboxes from a user. 
.NOTES
    Author: Josh Block
    Date: 06.12.24
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://o365reports.com/2022/07/13/get-shared-mailbox-in-office-365-using-powershell/
    https://learn.microsoft.com/en-us/microsoft-365/enterprise/block-user-accounts-with-microsoft-365-powershell?view=o365-worldwide
#>


Clear-Host

# Connect to Exchange Online via Entra Id
Function Connect_Exo{
    try {
        Write-Host -ForegroundColor Yellow 'Connecting to Exchange Online...'
        
        # Connect to Exchange Online
        Connect-ExchangeOnline | Clear-Host
        
        Write-Host -ForegroundColor Green 'Connected to Exchange Online.'
        Write-Host ""
    }
    catch {
        Write-Host "Failed to connect to Exchange Online. Ending script." -ForegroundColor Red
        exit
    }   
}

Connect_Exo

# Import CSV
$csvPath = Read-Host "Enter the path to the CSV file, remove quotes."
$csv = Import-Csv $csvPath

# CSV Headers is DisplayName and Email
# Create a progession bar
$progress = 0
$progressMax = $csv.Count
#$PercentComplete = ($progress / $progressMax * 100)

# Loop through each row in the CSV and remove the cloud mailbox
foreach ($row in $csv) {
    $progress++
    Write-Progress -Activity "Removing cloud mailboxes" -Status "Processing $progress of $progressMax" -PercentComplete ($progress / $progressMax * 100)
    
    $displayName = $row.DisplayName
    $email = $row.EmailAddress

    # Remove the cloud mailbox
    Set-User $email -PermanentlyClearPreviousMailboxInfo -Confirm:$false 
    Write-Host -ForegroundColor Green "Removed cloud mailbox for $displayName ($email)"

}
