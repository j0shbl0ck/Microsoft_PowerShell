<#
.SYNOPSIS
    Audits archive folders of a mailbox for specific folder patterns and totals messages. Uses the $_.FolderPath -like "*Restored at*IPF.Note" AND DOES NOT INCLUDE $_.FolderPath -notlike "/Deleted Items/*" so you will need to build a new script or adjust this one to include that if you want to.
.NOTES
    Author: Josh Block
    Date: 06.18.25
    Type: Public
    Version: 1.0.1
.LINK
    https://github.com/j0shbl0ck
    https://www.reddit.com/r/exchangeserver/comments/bn2w1x/getting_mailboxfolder_size_breakdown_on_inplace/
    https://practical365.com/reporting-mailbox-folder-sizes-with-powershell/
    https://stackoverflow.com/questions/77361004/using-powershell-to-move-emails-from-one-folder-to-another
#>

Clear-Host


Function Connect_Exo {
    try {
        Write-Host -ForegroundColor Yellow 'Connecting to Exchange Online...'
        Connect-ExchangeOnline | Out-Null
        Clear-Host
        Write-Host -ForegroundColor Green 'Connected to Exchange Online.'
        Write-Host ""
    }
    catch {
        Write-Host "Failed to connect to Exchange Online. Ending script." -ForegroundColor Red
        exit
    }
}

Function Get_MatchingFolders {
    param (
        [string]$Mailbox,
        [string]$Pattern
    )
    Write-Host "Searching archive folders for pattern: $Pattern`n"
    $results = Get-MailboxFolderStatistics -Identity $Mailbox -Archive |
        Where-Object { $_.FolderPath -like $Pattern }

    return $results
}

Function Display_Results {
    param (
        $Folders
    )
    if ($Folders.Count -eq 0) {
        Write-Host "No matching folders found." -ForegroundColor Yellow
        return
    }

    $Folders | Select-Object FolderPath, ItemsInFolder | Format-Table -AutoSize

    $total = ($Folders | Measure-Object -Property ItemsInFolder -Sum).Sum
    Write-Host "`nTotal messages across matching folders: $total" -ForegroundColor Green
}

# Main Execution Block
$Mailbox = Read-Host "Enter the mailbox (e.g., user@domain.com)"
$Pattern = Read-Host "Enter the folder name pattern to search (e.g., *Restored at*IPF.Note)"

Connect_Exo

$MatchingFolders = Get_MatchingFolders -Mailbox $Mailbox -Pattern $Pattern

Display_Results -Folders $MatchingFolders