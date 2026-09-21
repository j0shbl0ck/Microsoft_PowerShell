# Connect to Exchange Online if there isn't an active session
if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Connected' })) {
    Connect-ExchangeOnline -ShowBanner:$false
}

$emailRegex   = '^[^@\s]+@[^@\s]+\.[^@\s]+$'
$currentList  = @((Get-ExternalInOutlook).AllowList)
$toAdd        = [System.Collections.Generic.List[string]]::new()

Write-Host "`nCurrent allow list:" -ForegroundColor Cyan
if ($currentList.Count -gt 0) { $currentList | ForEach-Object { Write-Host "  $_" } }
else { Write-Host "  (empty)" }

# Collect addresses until the user enters a blank line
while ($true) {
    $address = (Read-Host "`nEmail address to add (press Enter when finished)").Trim().ToLower()

    if ([string]::IsNullOrWhiteSpace($address)) { break }

    if ($address -notmatch $emailRegex) {
        Write-Warning "'$address' is not a valid email address format."
        continue
    }
    if ($currentList -contains $address) {
        Write-Warning "'$address' is already on the allow list."
        continue
    }
    if ($toAdd -contains $address) {
        Write-Warning "'$address' was already entered."
        continue
    }

    $toAdd.Add($address)
    Write-Host "Queued: $address" -ForegroundColor Green
}

if ($toAdd.Count -eq 0) {
    Write-Host "`nNothing to add. Exiting." -ForegroundColor Yellow
    return
}

# Confirm before applying
Write-Host "`nAbout to add:" -ForegroundColor Cyan
$toAdd | ForEach-Object { Write-Host "  $_" }
$confirm = Read-Host "Proceed? (Y/N)"
if ($confirm -notmatch '^(y|yes)$') {
    Write-Host "Cancelled." -ForegroundColor Yellow
    return
}

try {
    Set-ExternalInOutlook -AllowList @{Add = $toAdd.ToArray()} -ErrorAction Stop
    Write-Host "`nAllow list updated." -ForegroundColor Green
}
catch {
    Write-Error "Failed to update allow list: $($_.Exception.Message)"
    return
}

# Show the result
$ExternalInOutlook = Get-ExternalInOutlook
$ExternalInOutlook | Format-List Identity, Enabled
$ExternalInOutlook.AllowList