<#
.SYNOPSIS
    Resolves EWS App IDs from the tenant EWS usage report into friendly application names.

.DESCRIPTION
    Cross-references the App IDs found in the M365 admin center EWS usage report export
    against Microsoft's published list of first-party application IDs and, for anything
    not on that list, queries Entra ID (app registrations and service principals) to
    resolve a display name. Outputs two timestamped CSVs (EwsApps_<timestamp>.csv and
    EwsAppsNotFound_<timestamp>.csv, sharing one timestamp per run) so repeat runs never
    collide or get blocked by a file still open in Excel — one with resolved app names,
    one with App IDs that couldn't be matched to anything in the tenant (candidates for
    manual follow-up / possible external or decommissioned apps).

    Every resolved row is also checked for a live service principal in THIS tenant,
    regardless of whether the app is first-party or not. Microsoft first-party apps
    (Outlook, Teams, Office, etc.) only get a local service principal once something in
    the tenant has actually consented to them — so a first-party app showing EWS usage
    with no tenant service principal is a real signal worth investigating, not a lookup
    failure. Output includes a Source column (how the name was resolved) and
    ConsentedInTenant / ServicePrincipalId columns (whether/where it's actually
    provisioned locally, so you can jump straight to it in Entra > Enterprise
    Applications instead of searching and coming up empty).

    Part of the Commerce Bank EWS retirement working set. Feeds the app inventory step
    of the EWS deprecation runbook (Phase 1 — app usage discovery).

    Graph session handling: if no Microsoft Graph session is active, the script signs
    in and disconnects it automatically when done (including on error). If a session
    is already active when the script starts, it's left connected on exit — the script
    won't tear down a session you were already using for other work.

.PARAMETER OutputPath
    Optional. Local folder to write output CSVs to. Defaults to Downloads.

.PARAMETER EwsUsageReportPath
    Optional. Path to the EWS usage report CSV exported from the M365 admin center
    (Reports > Usage > Exchange > EWS usage tab). If omitted, the script looks for a
    single EWSWeeklyUsage*.csv in -SearchFolder and uses it automatically; if it finds
    none or more than one, it opens a file picker pre-filtered to that pattern.

.PARAMETER SearchFolder
    Optional. Folder to auto-search for an EWSWeeklyUsage*.csv when -EwsUsageReportPath
    isn't given, and the starting folder for the file picker if it opens. Defaults to
    your Downloads folder.

.EXAMPLE
    .\Find-EwsApps.ps1
    # Zero-parameter run: auto-detects/prompts for the usage report in Downloads and
    # writes EwsApps_<timestamp>.csv / EwsAppsNotFound_<timestamp>.csv back to Downloads.

.EXAMPLE
    .\Find-EwsApps.ps1 -OutputPath C:\Temp\EWS
    # Auto-detects or prompts for the usage report CSV in Downloads, writes output to C:\Temp\EWS.

.EXAMPLE
    .\Find-EwsApps.ps1 -OutputPath C:\Temp\EWS -EwsUsageReportPath C:\Temp\EWS\EWSWeeklyUsage_8_27_2026_12_28_20.csv
    # Skips detection/picker and uses the exact file given.

.NOTES
    Version:      1.5.0 (Commerce Bank internal build)
    Author:       Josh Block
    Adapted from: Microsoft's Exchange-App-Usage-Reporting project (MIT licensed,
                  Copyright (c) Microsoft Corporation)
                  https://github.com/jmartinmsft/Exchange-App-Usage-Reporting
    GitHub:       https://github.com/j0shbl0ck (internal fork — not yet published)
    Requires:     Microsoft.Graph.Applications module, Application.Read.All (or higher)

    Original MIT license text is preserved below per license terms.
#>

<#
    MIT License

    Copyright (c) Microsoft Corporation.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE
#>

#region Parameters
[CmdletBinding(SupportsShouldProcess)]
param (
    [ValidateScript({ Test-Path $_ })]
    [Parameter(Mandatory = $false, HelpMessage = "Folder to write output CSVs to. Defaults to Downloads.")]
    [string] $OutputPath = (Join-Path $env:USERPROFILE "Downloads"),

    [ValidateScript({ Test-Path $_ })]
    [Parameter(Mandatory = $false, HelpMessage = "Path to the EWS usage report CSV exported from the M365 admin center. If omitted, the script auto-detects an EWSWeeklyUsage*.csv in -SearchFolder, or prompts with a file picker if it can't resolve to exactly one match.")]
    [string] $EwsUsageReportPath,

    [ValidateScript({ Test-Path $_ })]
    [Parameter(Mandatory = $false, HelpMessage = "Folder to auto-search for an EWSWeeklyUsage*.csv when -EwsUsageReportPath isn't specified. Defaults to Downloads.")]
    [string] $SearchFolder = (Join-Path $env:USERPROFILE "Downloads")
)
#endregion

#region Constants
$script:Version = "1.1.0"
$script:FirstPartyAppListUri = "https://raw.githubusercontent.com/merill/microsoft-info/main/_info/MicrosoftApps.csv"
$script:UsageReportPattern = "EWSWeeklyUsage*.csv"
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

function Select-EwsUsageReportFile {
    <#
        Resolves the EWS usage report CSV to use, in order of preference:
          1. Explicit -EwsUsageReportPath, if supplied
          2. Auto-detect: exactly one EWSWeeklyUsage*.csv in -SearchFolder
          3. File picker dialog, pre-filtered to EWSWeeklyUsage*.csv, starting in
             -SearchFolder — used both when auto-detect finds 0 or 2+ matches
    #>
    param(
        [string] $ExplicitPath,
        [string] $SearchFolder
    )

    if (-not [string]::IsNullOrEmpty($ExplicitPath)) {
        return $ExplicitPath
    }

    $candidates = @(Get-ChildItem -Path $SearchFolder -Filter $script:UsageReportPattern -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending)

    if ($candidates.Count -eq 1) {
        Write-Status "Auto-detected usage report: $($candidates[0].FullName)" -Level Success
        return $candidates[0].FullName
    }

    if ($candidates.Count -gt 1) {
        Write-Status "Found $($candidates.Count) EWSWeeklyUsage files in $SearchFolder — most recent is $($candidates[0].Name). Opening picker so you can confirm which one." -Level Warning
    }
    else {
        Write-Status "No EWSWeeklyUsage*.csv found in $SearchFolder — opening file picker." -Level Info
    }

    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.InitialDirectory = $SearchFolder
    $dialog.Filter = "EWS Usage Report (EWSWeeklyUsage*.csv)|EWSWeeklyUsage*.csv|All CSV files (*.csv)|*.csv"
    $dialog.Title = "Select the EWS usage report export"

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        throw "No file selected — aborting."
    }

    return $dialog.FileName
}


function Get-TenantServicePrincipalInfo {
    <#
        Checks whether an App ID has a service principal (Enterprise Application)
        provisioned in THIS tenant, regardless of whether it's a Microsoft first-party
        app or a third-party/custom one. First-party apps only get a local service
        principal once something in the tenant has actually consented to them, so
        "not present" is a meaningful signal, not a lookup failure.
    #>
    param(
        [Parameter(Mandatory = $true)][string] $AppId
    )

    try {
        $sp = Get-MgServicePrincipal -Filter "appId eq '$AppId'" -ErrorAction Stop
        if ($sp) {
            return [PSCustomObject]@{
                Consented       = $true
                ObjectId        = $sp.Id
                DisplayName     = $sp.DisplayName
                SignInAudience  = $sp.SignInAudience
            }
        }
    }
    catch {
        Write-Status "  Warning: service principal lookup failed for $AppId : $($_.Exception.Message)" -Level Warning
    }

    return [PSCustomObject]@{
        Consented      = $false
        ObjectId       = $null
        DisplayName    = $null
        SignInAudience = $null
    }
}


function Resolve-EwsAppName {
    <#
        Attempts to resolve a single App ID to a display name via app registration,
        falling back to service principal lookup if the direct app lookup misses.
    #>
    param(
        [Parameter(Mandatory = $true)][string] $AppId
    )

    try {
        $application = Get-MgApplication -Filter "AppId eq '$AppId'" -ErrorAction Stop
        if (-not [string]::IsNullOrEmpty($application.DisplayName)) {
            return $application.DisplayName
        }

        $servicePrincipal = Get-MgServicePrincipal -Filter "ServicePrincipalNames/any(s:s eq '$AppId')" -ErrorAction Stop
        if (-not [string]::IsNullOrEmpty($servicePrincipal.DisplayName)) {
            return $servicePrincipal.DisplayName
        }

        return $null
    }
    catch {
        Write-Status "Error resolving AppId $AppId : $($_.Exception.Message)" -Level Error
        throw
    }
}
#endregion

#region Main
Write-Status "Find-EwsApps v$script:Version — resolving EWS App IDs to display names" -Level Info

$script:ConnectedByThisScript = $false

try {
    #region Prerequisite checks
    if (-not (Get-Module -Name Microsoft.Graph.Applications -ListAvailable)) {
        Write-Status "Microsoft Graph PowerShell module is not installed. Install it with: Install-Module -Name Microsoft.Graph.Applications" -Level Error
        return
    }

    if (-not (Get-MgContext)) {
        Write-Status "Connecting to Microsoft Graph (Application.Read.All)..." -Level Info
        Connect-MgGraph -Scopes Application.Read.All -NoWelcome
        $script:ConnectedByThisScript = $true
    }
    else {
        Write-Status "Using existing Microsoft Graph session — will leave it connected on exit." -Level Info
    }
    #endregion

    #region Load first-party app reference list
    $firstPartyCsvPath = Join-Path $OutputPath "MicrosoftApps.csv"
    if ($PSCmdlet.ShouldProcess($firstPartyCsvPath, "Download latest Microsoft first-party app list")) {
        Write-Status "Downloading current first-party app list..." -Level Info
        Invoke-WebRequest -Uri $script:FirstPartyAppListUri -OutFile $firstPartyCsvPath
    }

    $microsoftApps = Import-Csv -Path $firstPartyCsvPath
    $firstPartyLookup = @{}
    foreach ($app in $microsoftApps) {
        $firstPartyLookup[$app.AppId] = $app.appDisplayName
    }
    Write-Status "Loaded $($firstPartyLookup.Count) known first-party app IDs." -Level Success
    #endregion

    #region Load tenant EWS usage report
    $resolvedReportPath = Select-EwsUsageReportFile -ExplicitPath $EwsUsageReportPath -SearchFolder $SearchFolder
    Write-Status "Using usage report: $resolvedReportPath" -Level Info
    $ewsApps = Import-Csv $resolvedReportPath | Sort-Object AppId -Unique
    Write-Status "Found $($ewsApps.Count) unique App IDs in the EWS usage report." -Level Info
    #endregion

    #region Resolve app names
    $resolvedApps = [System.Collections.Generic.List[object]]::new()
    $unresolvedApps = [System.Collections.Generic.List[object]]::new()

    foreach ($app in $ewsApps) {
        if ($firstPartyLookup.ContainsKey($app.AppId)) {
            Write-Status "Checking tenant consent for first-party app $($app.AppId)..." -Level Info
            $spInfo = Get-TenantServicePrincipalInfo -AppId $app.AppId
            $resolvedApps.Add([PSCustomObject]@{
                AppId              = $app.AppId
                DisplayName        = "$($firstPartyLookup[$app.AppId]) (MSFT)"
                Source             = "Microsoft First-Party (reference list)"
                ConsentedInTenant  = $spInfo.Consented
                ServicePrincipalId = $spInfo.ObjectId
            })
            continue
        }

        Write-Status "Resolving $($app.AppId)..." -Level Info
        try {
            $displayName = Resolve-EwsAppName -AppId $app.AppId
            if ($displayName) {
                $spInfo = Get-TenantServicePrincipalInfo -AppId $app.AppId
                $resolvedApps.Add([PSCustomObject]@{
                    AppId              = $app.AppId
                    DisplayName        = $displayName
                    Source             = "Tenant App Registration / Service Principal"
                    ConsentedInTenant  = $spInfo.Consented
                    ServicePrincipalId = $spInfo.ObjectId
                })
            }
            else {
                Write-Status "  No match found for $($app.AppId) — flagging for manual follow-up." -Level Warning
                $unresolvedApps.Add([PSCustomObject]@{ AppId = $app.AppId })
            }
        }
        catch {
            Write-Status "Stopping — unrecoverable error resolving $($app.AppId)." -Level Error
            break
        }
    }
    #endregion

    #region Output
    Write-Status "Resolved $($resolvedApps.Count) app(s); $($unresolvedApps.Count) unresolved." -Level Success

    $resolvedApps | Out-GridView -Title "EWS Applications"

    $runTimestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $resolvedCsvPath = Join-Path $OutputPath "EwsApps_$runTimestamp.csv"
    $unresolvedCsvPath = Join-Path $OutputPath "EwsAppsNotFound_$runTimestamp.csv"

    if ($PSCmdlet.ShouldProcess($resolvedCsvPath, "Write resolved app list")) {
        $resolvedApps | Export-Csv -Path $resolvedCsvPath -NoTypeInformation -Force
        Write-Status "Wrote $resolvedCsvPath" -Level Success
    }

    if ($PSCmdlet.ShouldProcess($unresolvedCsvPath, "Write unresolved app list")) {
        $unresolvedApps | Export-Csv -Path $unresolvedCsvPath -NoTypeInformation -Force
        Write-Status "Wrote $unresolvedCsvPath" -Level Success
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