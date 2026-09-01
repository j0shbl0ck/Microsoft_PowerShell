<#
.SYNOPSIS
    Reviews the tenant EWSAllowedAppIDs allow list in two steps: view/remove currently
    approved apps, then review/approve new candidates from a resolved
    EwsApps_<timestamp>.csv (Find-EwsApps.ps1).

.DESCRIPTION
    Exchange Online only — deliberately has no Microsoft Graph dependency. Earlier
    versions of this script also connected to Graph to live-resolve names for
    currently-approved apps not already in your EwsApps CSV, but ExchangeOnlineManagement
    and the Graph PowerShell SDK have a documented MSAL assembly clash when both connect
    in the same session (order-dependent, unreliable, and not worth fighting for what
    this script needs). Name resolution now relies only on your latest EwsApps CSV and
    Microsoft's first-party app list (a plain CSV download, no Graph call); anything not
    found in either shows as unresolved by App ID. Re-run Find-EwsApps.ps1 periodically
    to keep name coverage current if that matters to you.

    Step 1 — Currently Approved: shows every App ID already on the tenant's
    EwsAllowedAppIDs list with whatever name can be resolved from the sources above. You
    may select any of these to REMOVE.

    REMOVAL WARNING: removing an app here is not reversible through this tool. Undoing
    it later means re-adding that exact App ID (GUID) by hand — it won't reappear in
    the "currently approved" list to pick from once removed, AND it won't reliably
    resurface via the normal discovery path either: the M365 admin center EWS usage
    report only counts SUCCESSFUL call volume per SOAP action. Once an app is blocked
    (removed from the allow list, or blocked tenant-wide after Oct 1, 2026), its calls
    stop succeeding, so it stops generating fresh data in that report — re-running
    Find-EwsApps.ps1 later will not bring a blocked app back into view. This script's
    own change log CSV is therefore the only remaining record pairing that App ID with
    its resolved name — keep that file if there's any chance you'll need to restore
    access later.

    Step 2 — New Candidates: shows every app in your resolved EwsApps_<timestamp>.csv,
    with anything already approved (and not just removed in Step 1) marked, and lets
    you select which to APPROVE (add).

    The final list applied is: (currently approved, minus anything removed in Step 1)
    UNION (anything selected to approve in Step 2), de-duplicated. EwsAllowedAppIDs is a
    full replace on the Exchange side, so this script always computes and pushes the
    complete resulting list, never a partial diff.

    This script does NOT set EwsEnabled — that stays a separate deliberate step.
    Supports -WhatIf.

    Part of the Commerce Bank EWS retirement working set. Feeds the Allow List step of
    the EWS deprecation runbook (Phase 1 — end of August target).

.PARAMETER OutputPath
    Optional. Folder to write the change-log CSV to. Defaults to Downloads.

.PARAMETER SearchFolder
    Optional. Folder to auto-search for an EwsApps_*.csv when -EwsAppsCsvPath isn't
    given. Defaults to Downloads.

.PARAMETER EwsAppsCsvPath
    Optional. Path to a resolved EwsApps_<timestamp>.csv from Find-EwsApps.ps1. If
    omitted, auto-detects a single match in -SearchFolder or opens a file picker.

.PARAMETER DisableWAM
    Optional. Passes -DisableWAM to Connect-ExchangeOnline. Use this if a run fails with
    "Error Acquiring Token: System.NullReferenceException ... RuntimeBroker" — a known
    WAM broker bug in ExchangeOnlineManagement, unrelated to this script or the tenant.
    The broker context locks once a connection attempt has been made in a given
    PowerShell session, so this only works from a NEW PowerShell window.

.EXAMPLE
    .\Set-EwsAllowedAppIds.ps1 -WhatIf
    # Dry run through both steps — shows the resulting change summary without applying it.

.EXAMPLE
    .\Set-EwsAllowedAppIds.ps1
    # Full interactive run: view/remove current approvals, then review/add new ones.

.NOTES
    Version:      4.2.0 (Commerce Bank internal build — all numbered selection lists
                  (Step 1 removal, Step 2 approval, and the CSV file-picker console
                  fallback) now render through Format-Table for genuine even column
                  alignment and real headers, instead of manually joined text lines)
    Author:       Josh Block
    Companion to: Find-EwsApps.ps1, Find-EwsKioskExposure.ps1 (same working set)
    Requires:     ExchangeOnlineManagement module only
                  Exchange Online: rights to run Set-OrganizationConfig
#>

#region Parameters
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param (
    [ValidateScript({ Test-Path $_ })]
    [Parameter(Mandatory = $false, HelpMessage = "Folder to write the change-log CSV to. Defaults to Downloads.")]
    [string] $OutputPath = (Join-Path $env:USERPROFILE "Downloads"),

    [ValidateScript({ Test-Path $_ })]
    [Parameter(Mandatory = $false, HelpMessage = "Folder to auto-search for an EwsApps_*.csv when -EwsAppsCsvPath isn't specified. Defaults to Downloads.")]
    [string] $SearchFolder = (Join-Path $env:USERPROFILE "Downloads"),

    [ValidateScript({ Test-Path $_ })]
    [Parameter(Mandatory = $false, HelpMessage = "Path to a resolved EwsApps_<timestamp>.csv from Find-EwsApps.ps1. If omitted, auto-detects or prompts.")]
    [string] $EwsAppsCsvPath,

    [Parameter(Mandatory = $false, HelpMessage = "Passes -DisableWAM to Connect-ExchangeOnline. Use in a NEW PowerShell window if you hit the RuntimeBroker/WAM auth bug.")]
    [switch] $DisableWAM
)
#endregion

#region Constants
$script:Version = "3.0.0"
$script:EwsAppsCsvPattern = "EwsApps_*.csv"
$script:FirstPartyAppListUri = "https://raw.githubusercontent.com/merill/microsoft-info/main/_info/MicrosoftApps.csv"
#endregion

#region Helper Functions
function Write-Status {
    <#
        Color-coded console output. Keeps this consistent with the rest of the
        Commerce Bank M365 tooling set instead of bare Write-Host calls.
    #>
    param(
        [Parameter(Mandatory = $true)][string] $Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string] $Level = 'Info'
    )

    $color = switch ($Level) {
        'Info'    { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
    }

    Write-Host $Message -ForegroundColor $color
}

function Select-EwsAppsCsvFile {
    <#
        Resolves the EwsApps_<timestamp>.csv to use, in order of preference:
          1. Explicit -EwsAppsCsvPath, if supplied
          2. Auto-detect: exactly one EwsApps_*.csv in -SearchFolder
          3. Windows Explorer file picker, pre-filtered to EwsApps_*.csv, starting in
             -SearchFolder. (Unlike the approve/remove steps, a one-shot file browse
             doesn't have the back-and-forth friction of a checkbox grid, so this one
             stays a native picker rather than a console prompt.)
          4. If the picker is cancelled or unavailable, falls back to a console-numbered
             list of matches, or manual path entry if there are none.
    #>
    param(
        [string] $ExplicitPath,
        [string] $SearchFolder
    )

    if (-not [string]::IsNullOrEmpty($ExplicitPath)) {
        return $ExplicitPath
    }

    $candidates = @(Get-ChildItem -Path $SearchFolder -Filter $script:EwsAppsCsvPattern -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending)

    if ($candidates.Count -eq 1) {
        Write-Status "Auto-detected resolved app list: $($candidates[0].FullName)" -Level Success
        return $candidates[0].FullName
    }

    if ($candidates.Count -eq 0) {
        Write-Status "No EwsApps_*.csv found in $SearchFolder — opening file picker. (Run Find-EwsApps.ps1 first if you haven't yet.)" -Level Info
    }
    else {
        Write-Status "Found $($candidates.Count) EwsApps files in $SearchFolder — opening file picker so you can confirm which run to use." -Level Warning
    }

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.InitialDirectory = $SearchFolder
        $dialog.Filter = "Resolved EWS App List (EwsApps_*.csv)|EwsApps_*.csv|All CSV files (*.csv)|*.csv"
        $dialog.Title = "Select the resolved EWS app list from Find-EwsApps.ps1"

        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            return $dialog.FileName
        }
        Write-Status "File picker was cancelled — falling back to console selection." -Level Warning
    }
    catch {
        Write-Status "File picker unavailable ($($_.Exception.Message)) — falling back to console selection." -Level Warning
    }

    if ($candidates.Count -eq 0) {
        while ($true) {
            $manualPath = Read-Host "Enter the full path to your EwsApps CSV"
            if (Test-Path $manualPath -PathType Leaf) { return $manualPath }
            Write-Status "File not found: $manualPath — try again." -Level Error
        }
    }

    $fileRows = for ($i = 0; $i -lt $candidates.Count; $i++) {
        [PSCustomObject]@{
            '#'        = $i + 1
            Name       = $candidates[$i].Name
            Modified   = $candidates[$i].LastWriteTime
        }
    }
    ($fileRows | Format-Table -AutoSize | Out-String).TrimEnd() | Write-Host
    Write-Host ""
    while ($true) {
        $selection = Read-Host "Enter the number of the file to use"
        if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $candidates.Count) {
            return $candidates[[int]$selection - 1].FullName
        }
        Write-Status "Enter a number between 1 and $($candidates.Count)." -Level Error
    }
}

function Read-Selection {
    <#
        Console-native multi-select: prints a numbered table of $Items and prompts for
        a selection string. Accepts single numbers, comma lists, ranges (1-4), 'all',
        or a blank Enter for none. Replaces Out-GridView so nothing leaves the terminal.
        Returns the subset of $Items selected, in their original relative order.
    #>
    param(
        [Parameter(Mandatory = $true)] [AllowNull()] $Items,
        [string[]] $DisplayProperties = @('DisplayName', 'AppId'),
        [string] $Prompt = "Enter numbers (e.g. 1,3,5-7), 'all', or press Enter for none"
    )

    $itemArray = @($Items)
    if ($itemArray.Count -eq 0) { return @() }

    $rows = for ($i = 0; $i -lt $itemArray.Count; $i++) {
        $row = [ordered]@{ '#' = $i + 1 }
        foreach ($prop in $DisplayProperties) { $row[$prop] = $itemArray[$i].$prop }
        [PSCustomObject]$row
    }
    ($rows | Format-Table -AutoSize | Out-String).TrimEnd() | Write-Host
    Write-Host ""

    while ($true) {
        $response = Read-Host $Prompt
        if ([string]::IsNullOrWhiteSpace($response)) { return @() }
        if ($response.Trim().ToLower() -eq 'all') { return $itemArray }

        $selectedIndices = [System.Collections.Generic.SortedSet[int]]::new()
        $parseFailed = $false
        foreach ($part in ($response -split ',')) {
            $part = $part.Trim()
            if ($part -match '^\d+-\d+$') {
                $lo, $hi = $part -split '-'
                if ([int]$lo -gt [int]$hi) { $parseFailed = $true; break }
                for ($n = [int]$lo; $n -le [int]$hi; $n++) { [void]$selectedIndices.Add($n) }
            }
            elseif ($part -match '^\d+$') {
                [void]$selectedIndices.Add([int]$part)
            }
            else {
                $parseFailed = $true
                break
            }
        }

        if ($parseFailed) {
            Write-Status "Couldn't parse '$response' — use numbers, commas, and ranges like 1,3,5-7. Try again." -Level Error
            continue
        }

        $outOfRange = @($selectedIndices | Where-Object { $_ -lt 1 -or $_ -gt $itemArray.Count })
        if ($outOfRange.Count -gt 0) {
            Write-Status "Out of range: $($outOfRange -join ', ') — valid range is 1-$($itemArray.Count). Try again." -Level Error
            continue
        }

        return $selectedIndices | ForEach-Object { $itemArray[$_ - 1] }
    }
}

function Write-Section {
    <#
        Prints a visually distinct section banner so the console output reads in
        clear phases instead of one undifferentiated stream of lines.
    #>
    param(
        [Parameter(Mandatory = $true)][string] $Title
    )

    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkCyan
    Write-Host "  $Title" -ForegroundColor White -BackgroundColor DarkCyan
    Write-Host ("=" * 70) -ForegroundColor DarkCyan
}

function Write-Table {
    <#
        Prints a set of objects as a formatted console table so lists are visible
        in scrollback, not just inside a grid window that closes after selection.
    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)] $InputObject,
        [string[]] $Property
    )
    begin { $items = [System.Collections.Generic.List[object]]::new() }
    process { $items.Add($InputObject) }
    end {
        if ($items.Count -eq 0) { return }
        ($items | Format-Table -Property $Property -AutoSize | Out-String).TrimEnd() | Write-Host
    }
}
#endregion

#region Main
Write-Host ""
Write-Host "Set-EwsAllowedAppIds v$script:Version" -ForegroundColor White
Write-Host "EWSAllowedAppIDs allow list review — Exchange Online only" -ForegroundColor Gray

$script:ExoConnectedByThisScript = $false

try {
    #region Prerequisite checks
    if (-not (Get-Module -Name ExchangeOnlineManagement -ListAvailable)) {
        Write-Status "ExchangeOnlineManagement module is not installed. Install it with: Install-Module -Name ExchangeOnlineManagement" -Level Error
        return
    }

    Write-Section "Connecting to Exchange Online"
    $existingExoSession = Get-ConnectionInformation -ErrorAction SilentlyContinue
    if (-not $existingExoSession) {
        Write-Status "Connecting..." -Level Info
        if ($DisableWAM) {
            Write-Status "  (using -DisableWAM to route around the known RuntimeBroker/WAM auth bug)" -Level Info
            Connect-ExchangeOnline -ShowBanner:$false -DisableWAM
        }
        else {
            Connect-ExchangeOnline -ShowBanner:$false
        }
        $script:ExoConnectedByThisScript = $true
        Write-Status "Connected." -Level Success
    }
    else {
        Write-Status "Using existing Exchange Online session — will leave it connected on exit." -Level Info
    }
    #endregion

    #region Load reference data
    Write-Section "Current Tenant State"
    $orgConfig = Get-OrganizationConfig -ErrorAction Stop
    $policyConfig = Get-OrganizationConfig -RetrieveEwsOperationAccessPolicy -ErrorAction Stop
    # @($policyConfig.EwsAllowedAppIDs) alone would produce a 1-element array containing
    # $null when the property is unset (common — most tenants haven't configured this
    # yet), which then breaks downstream lookups expecting real App IDs. Filter it.
    $existingAllowList = @($policyConfig.EwsAllowedAppIDs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    [PSCustomObject]@{
        EwsEnabled        = $orgConfig.EwsEnabled
        AppsOnAllowList   = $existingAllowList.Count
    } | Write-Table
    Write-Status "(EwsEnabled is not changed by this script — that stays a separate manual step.)" -Level Info

    $ewsAppsCsvResolved = Select-EwsAppsCsvFile -ExplicitPath $EwsAppsCsvPath -SearchFolder $SearchFolder
    $resolvedApps = Import-Csv $ewsAppsCsvResolved
    $resolvedAppLookup = @{}
    foreach ($app in $resolvedApps) { $resolvedAppLookup[$app.AppId] = $app }
    Write-Status "Loaded app list: $ewsAppsCsvResolved ($($resolvedApps.Count) app(s))" -Level Info

    $firstPartyCsvPath = Join-Path $OutputPath "MicrosoftApps.csv"
    Invoke-WebRequest -Uri $script:FirstPartyAppListUri -OutFile $firstPartyCsvPath
    $firstPartyLookup = @{}
    foreach ($app in (Import-Csv -Path $firstPartyCsvPath)) { $firstPartyLookup[$app.AppId] = $app.appDisplayName }
    #endregion

    #region Step 1 — Currently Approved (view + optional removal)
    Write-Section "Step 1 of 2 — Currently Approved Apps"

    $unresolvedCount = 0
    $currentlyApproved = foreach ($appId in $existingAllowList) {
        if ($resolvedAppLookup.ContainsKey($appId)) {
            [PSCustomObject]@{
                AppId       = $appId
                DisplayName = $resolvedAppLookup[$appId].DisplayName
                Source      = "Latest EwsApps CSV"
            }
        }
        elseif ($firstPartyLookup.ContainsKey($appId)) {
            [PSCustomObject]@{
                AppId       = $appId
                DisplayName = "$($firstPartyLookup[$appId]) (MSFT)"
                Source      = "Microsoft First-Party (reference list)"
            }
        }
        else {
            $unresolvedCount++
            [PSCustomObject]@{
                AppId       = $appId
                DisplayName = "(unresolved — App ID: $appId)"
                Source      = "Not found in CSV or first-party list"
            }
        }
    }

    if (-not $currentlyApproved) {
        Write-Status "Nothing currently on the allow list — nothing to review for removal." -Level Info
        $toRemove = @()
    }
    else {
        if ($unresolvedCount -gt 0) {
            Write-Status "$unresolvedCount app(s) below have no name available from your latest CSV or the first-party list. Re-run Find-EwsApps.ps1 if you want a chance at resolving them before deciding." -Level Warning
        }

        Write-Host ""
        Write-Status "REMOVAL IS NOT REVERSIBLE THROUGH THIS TOOL:" -Level Error
        Write-Status "  Restoring access later means re-adding the exact App ID by hand — it will" -Level Warning
        Write-Status "  not reappear in this list once removed. WHY: the EWS usage report only" -Level Warning
        Write-Status "  counts SUCCESSFUL call volume, so a blocked app stops generating fresh" -Level Warning
        Write-Status "  data there too — re-running Find-EwsApps.ps1 will NOT bring it back into" -Level Warning
        Write-Status "  view. The change log this script writes is your only remaining record." -Level Warning

        Write-Host ""
        Write-Host "Currently approved on EwsAllowedAppIDs:" -ForegroundColor White
        $sortedApproved = @($currentlyApproved | Sort-Object DisplayName)
        $removeSelection = Read-Selection -Items $sortedApproved -DisplayProperties @('DisplayName', 'Source', 'AppId') `
            -Prompt "Enter numbers to REMOVE (e.g. 1,3,5-7), 'all', or press Enter to remove none"
        $toRemove = @($removeSelection.AppId)

        Write-Host ""
        if ($toRemove.Count -gt 0) {
            Write-Status "Marked for removal:" -Level Warning
            $removeSelection | Write-Table -Property DisplayName, AppId
        }
        else {
            Write-Status "No removals selected — current list will be kept." -Level Success
        }
    }
    #endregion

    #region Step 2 — New Candidates (review + approve)
    Write-Section "Step 2 of 2 — Approve New Candidates"

    $candidates = foreach ($app in $resolvedApps) {
        [PSCustomObject]@{
            AppId             = $app.AppId
            DisplayName       = $app.DisplayName
            Source            = $app.Source
            ConsentedInTenant = $app.ConsentedInTenant
            CurrentlyApproved = ($app.AppId -in $existingAllowList) -and ($app.AppId -notin $toRemove)
        }
    }

    Write-Host ""
    Write-Host "Candidates from $($resolvedApps.Count)-app resolved list (already-approved apps marked True below):" -ForegroundColor White
    Write-Status "Enter every app that should be APPROVED — include any already-approved apps you want to keep." -Level Warning

    $sortedCandidates = @($candidates | Sort-Object -Property @{Expression = 'CurrentlyApproved'; Descending = $true }, 'DisplayName')
    $approveSelection = Read-Selection -Items $sortedCandidates -DisplayProperties @('DisplayName', 'CurrentlyApproved', 'AppId') `
        -Prompt "Enter numbers to APPROVE (e.g. 1,3,5-7), 'all', or press Enter to approve none"
    $toAdd = @($approveSelection.AppId)

    Write-Host ""
    if ($toAdd.Count -gt 0) {
        Write-Status "Selected to approve:" -Level Success
        $approveSelection | Write-Table -Property DisplayName, AppId
    }
    else {
        Write-Status "Nothing selected to approve." -Level Info
    }
    #endregion

    #region Compute final list — uniqueness enforced
    $keptFromExisting = $existingAllowList | Where-Object { $_ -notin $toRemove }
    $newAllowList = @($keptFromExisting + $toAdd | Sort-Object -Unique)

    $added = $newAllowList | Where-Object { $_ -notin $existingAllowList }
    $removed = $existingAllowList | Where-Object { $_ -notin $newAllowList }
    $unchanged = $newAllowList | Where-Object { $_ -in $existingAllowList }

    Write-Section "Change Summary"
    [PSCustomObject]@{
        Added      = $added.Count
        Removed    = $removed.Count
        Unchanged  = $unchanged.Count
        TotalAfter = $newAllowList.Count
    } | Write-Table
    #endregion

    #region Apply
    if ($PSCmdlet.ShouldProcess("Organization Config", "Set EwsAllowedAppIDs to $($newAllowList.Count) app(s) ($($added.Count) added, $($removed.Count) removed)")) {
        # EwsAllowedAppIDs binds to a single comma-separated string, not an array —
        # passing $newAllowList directly throws "Cannot convert value to type System.String".
        Set-OrganizationConfig -EwsAllowedAppIDs ($newAllowList -join ",") -ErrorAction Stop
        Write-Status "EwsAllowedAppIDs updated successfully." -Level Success

        $verifyConfig = Get-OrganizationConfig -RetrieveEwsOperationAccessPolicy -ErrorAction Stop
        Write-Status "Verified: tenant now shows $($verifyConfig.EwsAllowedAppIDs.Count) app ID(s) on the allow list." -Level Success
    }
    #endregion

    #region Output — change log for the runbook / audit trail
    function Get-DisplayNameFor {
        param([string] $AppId)
        $match = $currentlyApproved | Where-Object { $_.AppId -eq $AppId } | Select-Object -First 1
        if ($match) { return $match.DisplayName }
        if ($resolvedAppLookup.ContainsKey($AppId)) { return $resolvedAppLookup[$AppId].DisplayName }
        return "(name not resolved)"
    }

    $runTimestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $changeLogPath = Join-Path $OutputPath "EwsAllowListChange_$runTimestamp.csv"

    $changeLog = [System.Collections.Generic.List[object]]::new()
    foreach ($appId in $added) {
        $changeLog.Add([PSCustomObject]@{
            AppId       = $appId
            DisplayName = Get-DisplayNameFor -AppId $appId
            Action      = "Added"
            PerformedBy = $env:USERNAME
            Timestamp   = Get-Date
        })
    }
    foreach ($appId in $unchanged) {
        $changeLog.Add([PSCustomObject]@{
            AppId       = $appId
            DisplayName = Get-DisplayNameFor -AppId $appId
            Action      = "Kept"
            PerformedBy = $env:USERNAME
            Timestamp   = Get-Date
        })
    }
    foreach ($appId in $removed) {
        $changeLog.Add([PSCustomObject]@{
            AppId       = $appId
            DisplayName = Get-DisplayNameFor -AppId $appId
            Action      = "Removed"
            PerformedBy = $env:USERNAME
            Timestamp   = Get-Date
        })
    }

    if ($PSCmdlet.ShouldProcess($changeLogPath, "Write allow-list change log")) {
        $changeLog | Export-Csv -Path $changeLogPath -NoTypeInformation -Force

        Write-Host ""
        Write-Host "Changes applied:" -ForegroundColor White
        $changeLog | Where-Object { $_.Action -ne 'Kept' } | Sort-Object Action, DisplayName | Write-Table -Property Action, DisplayName, AppId

        Write-Section "Done"
        Write-Status "Log saved to: $changeLogPath" -Level Success
        Write-Status "Keep this file — it's the only record of anything removed above." -Level Info
    }
    #endregion
}
catch {
    if ($_.Exception.Message -match 'RuntimeBroker|Object reference not set to an instance of an object' -and -not $DisableWAM) {
        Write-Status "Connection failed — this looks like the known ExchangeOnlineManagement WAM broker bug (RuntimeBroker NullReferenceException), not a script or tenant problem." -Level Error
        Write-Status "Open a NEW PowerShell window (the broker context is locked once a connection attempt has been made in this session) and re-run with -DisableWAM." -Level Warning
        throw
    }
    Write-Status "Unhandled error: $($_.Exception.Message)" -Level Error
    throw
}
finally {
    if ($script:ExoConnectedByThisScript) {
        Write-Status "Disconnecting Exchange Online session..." -Level Info
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Write-Status "Disconnected Exchange Online." -Level Success
    }
}
#endregion