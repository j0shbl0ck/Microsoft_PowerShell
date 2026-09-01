<#
.SYNOPSIS
    This script removes all cloud mailboxes from a user. 
.NOTES
    Author: Josh Block
    Date: 06.12.24
    Type: Public
    Version: 1.0.1
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

function Select-File {

    [CmdletBinding()]

    param(
        [Parameter(ParameterSetName="Single")]
        [Parameter(ParameterSetName="Multi")]
        [Parameter(ParameterSetName="Save")]
        [string]$StartingFolder = [environment]::getfolderpath("mydocuments"),

        [Parameter(ParameterSetName="Single")]
        [Parameter(ParameterSetName="Multi")]
        [Parameter(ParameterSetName="Save")]
        [string]$NameFilter = "All Files (*.*)|*.*",

        [Parameter(ParameterSetName="Single")]
        [Parameter(ParameterSetName="Multi")]
        [Parameter(ParameterSetName="Save")]
        [switch]$AllowAnyExtension,

        [Parameter(Mandatory=$true,ParameterSetName="Save")]
        [switch]$Save,

        [Parameter(Mandatory=$true,ParameterSetName="Multi")]
        [Alias("Multi")]
        [switch]$AllowMulti
    )

    if ($Save) {
        $Dialog = New-Object -TypeName System.Windows.Forms.SaveFileDialog
    } else {
        $Dialog = New-Object -TypeName System.Windows.Forms.OpenFileDialog
        if ($AllowMulti) {
            $Dialog.Multiselect = $true
        }
    }
    if ($AllowAnyExtension) {
        $NameFilter = $NameFilter + "|All Files (*.*)|*.*"
    }
    $Dialog.Filter = $NameFilter
    $Dialog.InitialDirectory = $StartingFolder
    [void]($Dialog.ShowDialog())
    $Dialog.FileNames
}

Connect_Exo

# Select the CSV File
Write-Host -ForegroundColor Yellow "Selecting the CSV file..."
$FileName = Select-File -StartingFolder "C:\Users\%username%\Documents" -NameFilter "CSV Files (*.CSV)|*.CSV"
Write-Host -ForegroundColor Green "Selected the CSV file: $FileName"
Write-Host -ForegroundColor Yellow "Importing the CSV file..."
$csv = Import-Csv $FileName

# CSV Headers is DisplayName and Email
# Create a progession bar
$progress = 0
$progressMax = $csv.Count

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