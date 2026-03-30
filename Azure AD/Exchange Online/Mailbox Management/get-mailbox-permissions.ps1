# Ensure Exchange Online module is available
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "Installing ExchangeOnlineManagement module..."
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
}

Import-Module ExchangeOnlineManagement

# Connect once
Write-Host "Connecting to Exchange Online..."
Connect-ExchangeOnline -ShowBanner:$false

# Helper function to resolve Display Name
function Get-DisplayName {
    param ($identity)

    try {
        $recipient = Get-EXORecipient -Identity $identity -ErrorAction Stop
        return $recipient.DisplayName
    }
    catch {
        return "Unknown"
    }
}

do {
    # Prompt for mailbox
    $mailbox = Read-Host "`nEnter the mailbox email address"

    # Get Full Access permissions
    Write-Host "Retrieving Full Access permissions..."
    $fullAccess = Get-MailboxPermission -Identity $mailbox |
        Where-Object {
            $_.AccessRights -contains "FullAccess" -and
            $_.IsInherited -eq $false -and
            $_.User -notlike "NT AUTHORITY\SELF"
        } |
        ForEach-Object {
            [PSCustomObject]@{
                User        = $_.User
                DisplayName = Get-DisplayName $_.User
                Permission  = "FullAccess"
            }
        }

    # Get Send As permissions
    Write-Host "Retrieving Send As permissions..."
    $sendAs = Get-RecipientPermission -Identity $mailbox |
        Where-Object {
            $_.AccessRights -contains "SendAs" -and
            $_.Trustee -ne "NT AUTHORITY\SELF"
        } |
        ForEach-Object {
            [PSCustomObject]@{
                User        = $_.Trustee
                DisplayName = Get-DisplayName $_.Trustee
                Permission  = "SendAs"
            }
        }

    # Combine and group
    $combined = $fullAccess + $sendAs

    $final = $combined | Group-Object User | ForEach-Object {
        $displayName = ($_.Group | Select-Object -First 1).DisplayName
        [PSCustomObject]@{
            User        = $_.Name
            DisplayName = $displayName
            Permission  = ($_.Group.Permission -join ", ")
        }
    }

    # Export path
    $downloadPath = [System.IO.Path]::Combine($env:USERPROFILE, "Downloads")
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeMailbox = $mailbox -replace '[^a-zA-Z0-9@._-]', '_'
    $filePath = Join-Path $downloadPath "MailboxPermissions_$($safeMailbox)_$timestamp.csv"

    # Export
    $final | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8

    Write-Host "Export complete: $filePath"

    # Strict Y/N validation loop
    do {
        $continue = Read-Host "`nDo you want to export another mailbox? (Y/N)"
        if ($continue -notmatch '^[YyNn]$') {
            Write-Host "Invalid input. Please enter Y or N."
        }
    } while ($continue -notmatch '^[YyNn]$')

} while ($continue -match '^[Yy]$')

# Disconnect after loop finishes
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "Session closed."