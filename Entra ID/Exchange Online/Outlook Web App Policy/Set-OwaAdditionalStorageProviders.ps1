<#
.SYNOPSIS
    This lists all OWA mailbox policies by number and sets AdditionalStorageProvidersAvailable to True or False on the selected policies.

.NOTES
    Author: Josh Block
    Date: 11.10.2026
    Type: Public
    Version: 1.0.0
.LINK
    https://m365scripts.com/exchange-online/restrict-external-storage-providers-in-owa/
    https://www.alitajran.com/restrict-access-to-storage-accounts-in-outlook-on-the-web/

#>

[CmdletBinding(SupportsShouldProcess)]
param()

$ScriptVersion = '1.0.0'

#region Helper Functions
function Write-Banner {
    Write-Host ''
    Write-Host '======================================================' -ForegroundColor Cyan
    Write-Host "  OWA Additional Storage Providers Manager  v$ScriptVersion" -ForegroundColor Cyan
    Write-Host '======================================================' -ForegroundColor Cyan
    Write-Host ''
}

function Get-PolicyTable {
    try {
        $policies = @(Get-OwaMailboxPolicy -ErrorAction Stop | Sort-Object @{ Expression = { -not $_.IsDefault } }, Name)
    }
    catch {
        Write-Host "[ERROR] Failed to retrieve OWA mailbox policies: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }

    $i = 0
    foreach ($p in $policies) {
        $i++
        [PSCustomObject]@{
            '#'                                 = $i
            Name                                = $p.Name
            IsDefault                           = $p.IsDefault
            AdditionalStorageProvidersAvailable = $p.AdditionalStorageProvidersAvailable
            Identity                            = $p.Identity
        }
    }
}

function Show-PolicyTable {
    param([object[]]$Table)

    Write-Host ''
    Write-Host ('{0,-4} {1,-45} {2,-10} {3}' -f '#', 'Policy Name', 'Default', 'AdditionalStorageProviders') -ForegroundColor White
    Write-Host ('{0,-4} {1,-45} {2,-10} {3}' -f '--', '-----------', '-------', '--------------------------') -ForegroundColor DarkGray

    foreach ($row in $Table) {
        $valueColor   = if ($row.AdditionalStorageProvidersAvailable) { 'Yellow' } else { 'Green' }
        $defaultLabel = if ($row.IsDefault) { 'Yes' } else { '' }

        Write-Host ('{0,-4} {1,-45} {2,-10} ' -f $row.'#', $row.Name, $defaultLabel) -NoNewline
        Write-Host $row.AdditionalStorageProvidersAvailable -ForegroundColor $valueColor
    }

    Write-Host ''
    Write-Host '  Yellow = providers allowed (Microsoft default)   Green = providers blocked' -ForegroundColor DarkGray
    Write-Host ''
}

function ConvertFrom-Selection {
    # Accepts: A | 3 | 1,3,5 | 2-4 | 1,3-5,7
    param(
        [string]$InputString,
        [int]$Max
    )

    $InputString = $InputString.Trim()
    if ($InputString -match '^(?i)a(ll)?$') { return 1..$Max }

    $numbers = New-Object System.Collections.Generic.List[int]
    foreach ($part in ($InputString -split ',')) {
        $part = $part.Trim()
        if ($part -match '^(\d+)\s*-\s*(\d+)$') {
            $start = [int]$Matches[1]; $end = [int]$Matches[2]
            if ($start -gt $end) { $start, $end = $end, $start }
            $start..$end | ForEach-Object { $numbers.Add($_) }
        }
        elseif ($part -match '^\d+$') {
            $numbers.Add([int]$part)
        }
        else {
            throw "Invalid entry '$part'."
        }
    }

    $outOfRange = $numbers | Where-Object { $_ -lt 1 -or $_ -gt $Max }
    if ($outOfRange) { throw "Out of range: $($outOfRange -join ', '). Valid range is 1-$Max." }

    return ($numbers | Sort-Object -Unique)
}
#endregion

#region Connect to Exchange Online
Write-Banner

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host '[ERROR] ExchangeOnlineManagement module is not installed.' -ForegroundColor Red
    Write-Host '        Install-Module ExchangeOnlineManagement -Scope CurrentUser' -ForegroundColor Yellow
    return
}

try {
    $connection = Get-ConnectionInformation -ErrorAction SilentlyContinue |
        Where-Object { $_.State -eq 'Connected' -and $_.ConnectionUri -like '*outlook.office365.com*' } |
        Select-Object -First 1

    if ($connection) {
        Write-Host "[INFO] Using existing Exchange Online session: $($connection.UserPrincipalName)" -ForegroundColor Cyan
    }
    else {
        Write-Host '[INFO] Connecting to Exchange Online...' -ForegroundColor Cyan
        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
        $connection = Get-ConnectionInformation | Select-Object -First 1
        Write-Host "[OK]   Connected as $($connection.UserPrincipalName)" -ForegroundColor Green
    }
}
catch {
    Write-Host "[ERROR] Could not connect to Exchange Online: $($_.Exception.Message)" -ForegroundColor Red
    return
}
#endregion

#region Main Loop
do {
    #region List Policies
    Write-Host '[INFO] Retrieving OWA mailbox policies...' -ForegroundColor Cyan
    $table = @(Get-PolicyTable)

    if (-not $table -or $table.Count -eq 0) {
        Write-Host '[WARN] No OWA mailbox policies found.' -ForegroundColor Yellow
        break
    }

    Write-Host "[OK]   Found $($table.Count) polic$(if ($table.Count -eq 1) {'y'} else {'ies'})." -ForegroundColor Green
    Show-PolicyTable -Table $table
    #endregion

    #region Select Policies
    $selected = $null
    while (-not $selected) {
        $raw = Read-Host "Select policies to change (e.g. 1 | 1,3 | 2-4 | A for all | Q to quit)"
        if ($raw -match '^(?i)q(uit)?$') { $selected = 'QUIT'; break }
        try {
            $selected = @(ConvertFrom-Selection -InputString $raw -Max $table.Count)
        }
        catch {
            Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    if ($selected -eq 'QUIT') { break }

    $targets = $table | Where-Object { $selected -contains $_.'#' }
    #endregion

    #region Choose Value
    $newValue = $null
    while ($null -eq $newValue) {
        $raw = (Read-Host 'Set AdditionalStorageProvidersAvailable to [T]rue (allow) or [F]alse (block)').Trim()
        switch -Regex ($raw) {
            '^(?i)t(rue)?$'  { $newValue = $true }
            '^(?i)f(alse)?$' { $newValue = $false }
            default          { Write-Host '[ERROR] Enter T or F.' -ForegroundColor Red }
        }
    }
    #endregion

    #region Build Plan
    $toChange = @($targets | Where-Object { $_.AdditionalStorageProvidersAvailable -ne $newValue })
    $noChange = @($targets | Where-Object { $_.AdditionalStorageProvidersAvailable -eq $newValue })

    Write-Host ''
    Write-Host '---------------- Change Plan ----------------' -ForegroundColor White
    foreach ($t in $toChange) {
        Write-Host ("  [CHANGE] #{0,-3} {1}: {2} -> {3}" -f $t.'#', $t.Name, $t.AdditionalStorageProvidersAvailable, $newValue) -ForegroundColor Yellow
    }
    foreach ($t in $noChange) {
        Write-Host ("  [SKIP]   #{0,-3} {1}: already {2}" -f $t.'#', $t.Name, $newValue) -ForegroundColor DarkGray
    }
    Write-Host '---------------------------------------------' -ForegroundColor White
    Write-Host ''

    if ($toChange.Count -eq 0) {
        Write-Host '[INFO] Nothing to change.' -ForegroundColor Cyan
    }
    else {
        #region Run Mode
        $mode = $null
        if ($WhatIfPreference) {
            $mode = 'P'
            Write-Host '[INFO] -WhatIf detected; running as dry run.' -ForegroundColor Cyan
        }
        while (-not $mode) {
            $raw = (Read-Host 'Run mode: [P]review only (dry run), [A]pply changes, or [C]ancel').Trim().ToUpper()
            if ($raw -in 'P', 'A', 'C') { $mode = $raw } else { Write-Host '[ERROR] Enter P, A, or C.' -ForegroundColor Red }
        }
        #endregion

        #region Apply
        switch ($mode) {
            'C' { Write-Host '[INFO] Cancelled. No changes made.' -ForegroundColor Cyan }

            'P' {
                foreach ($t in $toChange) {
                    Write-Host "[DRY RUN] Would run: Set-OwaMailboxPolicy -Identity '$($t.Name)' -AdditionalStorageProvidersAvailable `$$newValue" -ForegroundColor Magenta
                }
                Write-Host '[INFO] Dry run complete. No changes made.' -ForegroundColor Cyan
            }

            'A' {
                $results = foreach ($t in $toChange) {
                    if ($PSCmdlet.ShouldProcess($t.Name, "Set AdditionalStorageProvidersAvailable to $newValue")) {
                        try {
                            Set-OwaMailboxPolicy -Identity $t.Identity -AdditionalStorageProvidersAvailable $newValue -ErrorAction Stop
                            $verify = (Get-OwaMailboxPolicy -Identity $t.Identity -ErrorAction Stop).AdditionalStorageProvidersAvailable

                            if ($verify -eq $newValue) {
                                Write-Host "[OK]   $($t.Name): now $verify" -ForegroundColor Green
                                [PSCustomObject]@{ Policy = $t.Name; Result = 'Updated'; Value = $verify }
                            }
                            else {
                                Write-Host "[WARN] $($t.Name): set ran but value reads $verify" -ForegroundColor Yellow
                                [PSCustomObject]@{ Policy = $t.Name; Result = 'Verify mismatch'; Value = $verify }
                            }
                        }
                        catch {
                            Write-Host "[ERROR] $($t.Name): $($_.Exception.Message)" -ForegroundColor Red
                            [PSCustomObject]@{ Policy = $t.Name; Result = 'Failed'; Value = $t.AdditionalStorageProvidersAvailable }
                        }
                    }
                }

                $ok   = @($results | Where-Object Result -eq 'Updated').Count
                $fail = @($results | Where-Object Result -ne 'Updated').Count
                Write-Host ''
                Write-Host "[SUMMARY] Updated: $ok   Failed/Mismatch: $fail   Skipped: $($noChange.Count)" -ForegroundColor $(if ($fail) { 'Yellow' } else { 'Green' })
                Write-Host '[INFO]    Allow 1-24 hours for the change to reach all users in OWA.' -ForegroundColor Cyan
            }
        }
        #endregion
    }
    #endregion

    Write-Host ''
    $again = (Read-Host 'Make another change? [Y/N]').Trim()
} while ($again -match '^(?i)y(es)?$')
#endregion

#region Cleanup
Write-Host ''
$disc = (Read-Host 'Disconnect from Exchange Online? [Y/N]').Trim()
if ($disc -match '^(?i)y(es)?$') {
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction Stop
        Write-Host '[OK]   Disconnected.' -ForegroundColor Green
    }
    catch {
        Write-Host "[WARN] Disconnect failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
Write-Host '[DONE]' -ForegroundColor Cyan
#endregion