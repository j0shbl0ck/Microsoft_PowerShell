<#
.SYNOPSIS
    Imports members into the single cloud DL: DL-Vacation Purchase Plan
.NOTES
    Author: Josh Block
    Date: 11.17.25
    Type: Private
    Version: 2.0.0 (EXO Only)
#>

Clear-Host
Write-Host -ForegroundColor Cyan "Loading Exchange Online..."

# Connect to Exchange Online
try {
    Connect-ExchangeOnline -ErrorAction Stop
    Write-Host -ForegroundColor Green "Connected to Exchange Online."
}
catch {
    Write-Host -ForegroundColor Red "Failed to connect to Exchange Online."
    exit
}

# The only DL this script operates on
$DLName = "DL-Vacation Purchase Plan"
Write-Host -ForegroundColor Cyan "Target Distribution List: $DLName"

# Validate DL exists
$DL = Get-DistributionGroup -Identity $DLName -ErrorAction SilentlyContinue
if (-not $DL) {
    Write-Host -ForegroundColor Red "❌ DL '$DLName' not found in Exchange Online."
    exit
}

Write-Host -ForegroundColor Green "Found DL: $($DL.DisplayName)"
Write-Host ""

# Open File Dialog for CSV
Add-Type -AssemblyName System.Windows.Forms
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Filter = "CSV files (*.csv)|*.csv"
$dialog.Title = "Select CSV containing emails"
$null = $dialog.ShowDialog()
$filePath = $dialog.FileName

if (-not (Test-Path $filePath)) {
    Write-Host -ForegroundColor Red "No valid CSV selected. Exiting."
    exit
}

Write-Host -ForegroundColor Yellow "Importing CSV: $filePath"
$csv = Import-Csv $filePath

if ($csv.Count -eq 0) {
    Write-Host -ForegroundColor Red "CSV is empty. Exiting."
    exit
}

Write-Host -ForegroundColor Green "Imported $($csv.Count) rows."
Write-Host ""

# Get current members (email normalized)
$current = (Get-DistributionGroupMember -Identity $DLName -ResultSize Unlimited).PrimarySMTPAddress.ToLower()

# Tracking arrays
$added = @()
$skipped = @()
$failed = @()

$total = $csv.Count
$index = 0

foreach ($row in $csv) {
    $index++
    $percent = [math]::Round(($index / $total) * 100)

    Write-Progress -Activity "Processing CSV" `
        -Status "Working: $index of $total" `
        -PercentComplete $percent

    $email = $row.WorkEmail.ToLower().Trim()

    if (-not $email) {
        $failed += "Blank email in row $index"
        continue
    }

    # Already in group?
    if ($current -contains $email) {
        $skipped += $email
        continue
    }

    try {
        Add-DistributionGroupMember -Identity $DLName -Member $email -ErrorAction Stop
        $added += $email
        $current += $email
    }
    catch {
        $failed += $email
    }
}

Write-Progress -Activity "Complete" -Completed

Write-Host ""
Write-Host -ForegroundColor Cyan "========== Summary =========="
Write-Host -ForegroundColor Green "Added: $($added.Count)"
Write-Host -ForegroundColor Yellow "Skipped (already members): $($skipped.Count)"
Write-Host -ForegroundColor Red "Failed to Add: $($failed.Count)"
Write-Host ""

# Log outputs
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if ($skipped.Count -gt 0) {
    $path = "$env:USERPROFILE\Desktop\Skipped_$timestamp.txt"
    $skipped | Out-File -FilePath $path -Encoding UTF8
    Write-Host -ForegroundColor Yellow "Skipped list saved to: $path"
}

if ($failed.Count -gt 0) {
    $path = "$env:USERPROFILE\Desktop\Failed_$timestamp.txt"
    $failed | Out-File -FilePath $path -Encoding UTF8
    Write-Host -ForegroundColor Red "Failed list saved to: $path"
}

Write-Host -ForegroundColor Green "Done."