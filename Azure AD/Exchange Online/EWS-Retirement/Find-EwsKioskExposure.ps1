<#
.SYNOPSIS
    Identifies Kiosk/F1/F3-licensed mailboxes with sign-in activity against apps known
    to call EWS, ahead of the October 1, 2026 license-based EWS block.

.DESCRIPTION
    Three-step audit:
      1. You select which SKUs in your tenant to flag (Kiosk/F1/F3 and similar) from an
         interactive grid of your actual subscribed SKUs — no hardcoded SKU IDs, since
         those vary and drift over time. Matching is CONTAINS, not EQUALS: a user is
         flagged if they hold ANY of the selected SKUs, regardless of whatever else is
         on their account — add-ons like Power BI Free, Teams Exploratory, Defender
         Discovery, etc, or any other license, are ignored. (An earlier version required
         a user's entire license set to match the selected SKUs exactly, which silently
         excluded almost everyone carrying any incidental extra SKU — most real users.)
      2. For each App ID in your resolved EWS app list (EwsApps_<timestamp>.csv from
         Find-EwsApps.ps1), pulls sign-in activity within the lookback window and
         collects which users signed into that app.
      3. Intersects the two sets on UserPrincipalName.

    CAVEAT: a sign-in to an app that calls EWS is not proof that specific sign-in was an
    EWS call — that app may do other things too. Treat the output as an investigation
    list, not a confirmed-impact list. For higher-precision (but narrower — only mailboxes
    with auditing enabled) results, see Microsoft's Find-EwsUsage.ps1 -Operation
    GetUserLicenses against an audit log query instead.

    Part of the Commerce Bank EWS retirement working set. Feeds the Kiosk/Frontline
    license audit step of the EWS deprecation runbook (Phase 1).

.PARAMETER OutputPath
    Optional. Folder to write output CSVs to. Defaults to Downloads.

.PARAMETER SearchFolder
    Optional. Folder to auto-search for an EwsApps_*.csv (from Find-EwsApps.ps1) when
    -EwsAppsCsvPath isn't given, and the starting folder for the file picker if it opens.
    Defaults to Downloads.

.PARAMETER EwsAppsCsvPath
    Optional. Path to a resolved EwsApps_<timestamp>.csv from Find-EwsApps.ps1. If
    omitted, auto-detects a single match in -SearchFolder or opens a file picker.

.PARAMETER SignInLookbackDays
    Optional. How many days of sign-in log history to search. Defaults to 30 — matches
    typical Entra ID P1/P2 sign-in log retention. Free-tier tenants only retain 7 days;
    adjust down if Get-MgAuditLogSignIn returns errors for the full range.

.EXAMPLE
    .\Find-EwsKioskExposure.ps1
    # Zero-parameter run: auto-detects the latest EwsApps_*.csv in Downloads, prompts you
    # to pick restricted SKUs from your tenant, and writes results back to Downloads.

.NOTES
    Version:      1.4.0 (Commerce Bank internal build — output CSVs renamed to
                  F1F3KioskExposure_<timestamp>.csv and F1F3KioskLicenseUsers_<timestamp>.csv
                  to reflect that the audit covers F1/F3/Kiosk, not just Kiosk. Script
                  filename left unchanged for documentation consistency.)
    Author:       Josh Block
    Companion to: Find-EwsApps.ps1 (same working set)
    Requires:     Microsoft.Graph.Users, Microsoft.Graph.Identity.DirectoryManagement,
                  Microsoft.Graph.Reports modules
                  Graph scopes: User.Read.All, AuditLog.Read.All, Directory.Read.All
#>

#region Parameters
[CmdletBinding(SupportsShouldProcess)]
param (
    [ValidateScript({ Test-Path $_ })]
    [Parameter(Mandatory = $false, HelpMessage = "Folder to write output CSVs to. Defaults to Downloads.")]
    [string] $OutputPath = (Join-Path $env:USERPROFILE "Downloads"),

    [ValidateScript({ Test-Path $_ })]
    [Parameter(Mandatory = $false, HelpMessage = "Folder to auto-search for an EwsApps_*.csv when -EwsAppsCsvPath isn't specified. Defaults to Downloads.")]
    [string] $SearchFolder = (Join-Path $env:USERPROFILE "Downloads"),

    [ValidateScript({ Test-Path $_ })]
    [Parameter(Mandatory = $false, HelpMessage = "Path to a resolved EwsApps_<timestamp>.csv from Find-EwsApps.ps1. If omitted, auto-detects or prompts.")]
    [string] $EwsAppsCsvPath,

    [Parameter(Mandatory = $false, HelpMessage = "Days of sign-in log history to search. Defaults to 30.")]
    [ValidateRange(1, 90)]
    [int] $SignInLookbackDays = 30
)
#endregion

#region Constants
$script:Version = "1.0.0"
$script:EwsAppsCsvPattern = "EwsApps_*.csv"
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
          2. Auto-detect: exactly one EwsApps_*.csv in -SearchFolder (most recent if
             the pattern also needs disambiguation — but multiple always opens the picker
             so you consciously confirm which run you're auditing against)
          3. File picker dialog, pre-filtered to EwsApps_*.csv, starting in -SearchFolder
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

    if ($candidates.Count -gt 1) {
        Write-Status "Found $($candidates.Count) EwsApps files in $SearchFolder — most recent is $($candidates[0].Name). Opening picker so you can confirm which run to use." -Level Warning
    }
    else {
        Write-Status "No EwsApps_*.csv found in $SearchFolder — opening file picker. (Run Find-EwsApps.ps1 first if you haven't yet.)" -Level Info
    }

    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.InitialDirectory = $SearchFolder
    $dialog.Filter = "Resolved EWS App List (EwsApps_*.csv)|EwsApps_*.csv|All CSV files (*.csv)|*.csv"
    $dialog.Title = "Select the resolved EWS app list from Find-EwsApps.ps1"

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        throw "No file selected — aborting."
    }

    return $dialog.FileName
}

function Get-RestrictedSkuSelection {
    <#
        Shows every subscribed SKU in the tenant in one interactive grid and lets the
        admin pick which ones count as restricted (Kiosk/F1/F3/etc). Deliberately
        interactive rather than hardcoded — SkuPartNumbers and their meanings vary and
        occasionally get renamed, so tenant-confirmed selection beats a guessed list.

        Matching is CONTAINS, not EQUALS: a user is flagged if they hold ANY of the
        selected SKUs, regardless of whatever else is on their account (add-ons like
        Power BI Free, Teams Exploratory, Defender Discovery, etc, or anything else).
        An earlier version required a user's entire license set to match, which
        silently excluded almost everyone carrying any incidental extra SKU.
    #>
    $allSkus = Get-MgSubscribedSku -All -ErrorAction Stop |
        Select-Object SkuId, SkuPartNumber, @{N = 'ConsumedUnits'; E = { $_.ConsumedUnits } }, @{N = 'Enabled'; E = { $_.PrepaidUnits.Enabled } } |
        Sort-Object SkuPartNumber

    Write-Status "Select the SKUs to flag (Kiosk, F1, F3, and similar), then click OK. A user matches if they hold ANY of these, regardless of other licenses on their account." -Level Warning
    $selection = $allSkus | Out-GridView -Title "Select SKUs to flag (Kiosk/F1/F3)" -OutputMode Multiple

    if (-not $selection -or $selection.Count -eq 0) {
        throw "No SKUs selected — nothing to audit against. Aborting."
    }

    Write-Status "Selected $($selection.Count) SKU(s) to flag: $($selection.SkuPartNumber -join ', ')" -Level Success
    return @($selection.SkuId)
}
#endregion

#region Main
Write-Status "Find-EwsKioskExposure v$script:Version — Kiosk/F1/F3 EWS exposure audit" -Level Info

$script:ConnectedByThisScript = $false

try {
    #region Prerequisite checks
    $requiredModules = @('Microsoft.Graph.Users', 'Microsoft.Graph.Identity.DirectoryManagement', 'Microsoft.Graph.Reports')
    $missingModules = $requiredModules | Where-Object { -not (Get-Module -Name $_ -ListAvailable) }
    if ($missingModules) {
        Write-Status "Missing required module(s): $($missingModules -join ', '). Install with: Install-Module -Name $($missingModules -join ',')" -Level Error
        return
    }

    $script:RequiredScopes = @('User.Read.All', 'AuditLog.Read.All', 'Directory.Read.All')
    $existingContext = Get-MgContext

    if (-not $existingContext) {
        Write-Status "Connecting to Microsoft Graph ($($script:RequiredScopes -join ', '))..." -Level Info
        Connect-MgGraph -Scopes $script:RequiredScopes -NoWelcome
        $script:ConnectedByThisScript = $true
    }
    else {
        $missingScopes = $script:RequiredScopes | Where-Object { $_ -notin $existingContext.Scopes }
        if ($missingScopes) {
            Write-Status "Existing Graph session is missing scope(s): $($missingScopes -join ', '). Reconnecting with the full scope set required by this script..." -Level Warning
            Connect-MgGraph -Scopes $script:RequiredScopes -NoWelcome
            # Session existed before this run started, so it's left connected on exit either way —
            # we're only upgrading its scopes, not creating it, so $ConnectedByThisScript stays $false.
        }
        else {
            Write-Status "Using existing Microsoft Graph session — already has required scopes. Will leave it connected on exit." -Level Info
        }
    }
    #endregion

    #region Step 1 — Restricted-license mailboxes
    Write-Status "Step 1: identifying mailboxes on flagged licenses..." -Level Info
    $restrictedSkuIds = Get-RestrictedSkuSelection

    Write-Status "Pulling user license assignments (this can take a while in large tenants)..." -Level Info
    $allUsers = Get-MgUser -All -Property Id, UserPrincipalName, DisplayName, AssignedLicenses -ErrorAction Stop

    # Contains, not equals: a user is flagged if they hold ANY selected SKU, regardless
    # of whatever else is assigned (add-ons, unrelated free SKUs, or anything else).
    $restrictedUsers = $allUsers | Where-Object {
        ($_.AssignedLicenses.SkuId | Where-Object { $_ -in $restrictedSkuIds }).Count -gt 0
    }
    Write-Status "Found $($restrictedUsers.Count) mailbox(es) holding at least one flagged license." -Level Success
    #endregion

    #region Step 2 — EWS app sign-in activity
    Write-Status "Step 2: checking sign-in activity for EWS-flagged apps (last $SignInLookbackDays days)..." -Level Info
    $ewsAppsCsvResolved = Select-EwsAppsCsvFile -ExplicitPath $EwsAppsCsvPath -SearchFolder $SearchFolder
    Write-Status "Using resolved app list: $ewsAppsCsvResolved" -Level Info
    $ewsApps = Import-Csv $ewsAppsCsvResolved

    $sinceDate = (Get-Date).AddDays(-$SignInLookbackDays).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $signInActivity = [System.Collections.Generic.List[object]]::new()

    foreach ($app in $ewsApps) {
        Write-Status "  Querying sign-ins for $($app.DisplayName) [$($app.AppId)]..." -Level Info
        try {
            $filter = "appId eq '$($app.AppId)' and createdDateTime ge $sinceDate"
            $signIns = Get-MgAuditLogSignIn -Filter $filter -All -ErrorAction Stop
            foreach ($signIn in $signIns) {
                $signInActivity.Add([PSCustomObject]@{
                    UserPrincipalName = $signIn.UserPrincipalName
                    AppId             = $app.AppId
                    AppDisplayName    = $app.DisplayName
                    LastSignIn        = $signIn.CreatedDateTime
                })
            }
        }
        catch {
            Write-Status "  Warning: sign-in query failed for $($app.DisplayName): $($_.Exception.Message)" -Level Warning
        }
    }

    # Collapse to most-recent sign-in per user/app pair
    $signInActivity = $signInActivity |
        Where-Object { -not [string]::IsNullOrEmpty($_.UserPrincipalName) } |
        Group-Object UserPrincipalName, AppId |
        ForEach-Object { $_.Group | Sort-Object LastSignIn -Descending | Select-Object -First 1 }

    Write-Status "Found sign-in activity from $(($signInActivity.UserPrincipalName | Sort-Object -Unique).Count) unique user(s) across flagged apps." -Level Success
    #endregion

    #region Step 3 — Intersect
    Write-Status "Step 3: intersecting restricted-license users with EWS-app sign-in activity..." -Level Info
    $restrictedUpns = $restrictedUsers.UserPrincipalName

    $exposedUsers = $signInActivity | Where-Object { $_.UserPrincipalName -in $restrictedUpns }

    $exposureReport = foreach ($hit in $exposedUsers) {
        $userDetail = $restrictedUsers | Where-Object { $_.UserPrincipalName -eq $hit.UserPrincipalName } | Select-Object -First 1
        [PSCustomObject]@{
            UserPrincipalName = $hit.UserPrincipalName
            DisplayName       = $userDetail.DisplayName
            AppId             = $hit.AppId
            AppDisplayName    = $hit.AppDisplayName
            LastSignIn        = $hit.LastSignIn
        }
    }

    if ($exposureReport) {
        Write-Status "$($exposureReport.Count) exposure hit(s) found — restricted-license mailboxes with sign-in activity against EWS-flagged apps." -Level Warning
    }
    else {
        Write-Status "No overlap found between restricted-license mailboxes and EWS-app sign-in activity in the lookback window." -Level Success
    }
    #endregion

    #region Output
    $exposureReport | Out-GridView -Title "Kiosk/F1/F3 EWS Exposure"

    $runTimestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $exposureCsvPath = Join-Path $OutputPath "F1F3KioskExposure_$runTimestamp.csv"
    $allRestrictedCsvPath = Join-Path $OutputPath "F1F3KioskLicenseUsers_$runTimestamp.csv"

    if ($PSCmdlet.ShouldProcess($exposureCsvPath, "Write exposure report")) {
        $exposureReport | Export-Csv -Path $exposureCsvPath -NoTypeInformation -Force
        Write-Status "Wrote $exposureCsvPath" -Level Success
    }

    if ($PSCmdlet.ShouldProcess($allRestrictedCsvPath, "Write full restricted-license user list")) {
        $restrictedUsers | Select-Object UserPrincipalName, DisplayName |
            Export-Csv -Path $allRestrictedCsvPath -NoTypeInformation -Force
        Write-Status "Wrote $allRestrictedCsvPath (full restricted-license population, for reference)" -Level Success
    }
    #endregion
}
catch {
    Write-Status "Unhandled error: $($_.Exception.Message)" -Level Error
    throw
}
finally {
    if ($script:ConnectedByThisScript) {
        Write-Status "Disconnecting Microsoft Graph session..." -Level Info
        Disconnect-MgGraph | Out-Null
        Write-Status "Disconnected." -Level Success
    }
}
#endregion
