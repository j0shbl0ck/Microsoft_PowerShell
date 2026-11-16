<#
.SYNOPSIS
    Creates an Entra ID app registration and enterprise app for Microsoft Bookings with Graph application permissions (app-only jobs) and delegated permissions (admin-run booking page creation), grants admin consent for both, configures interactive sign-in, and issues a client secret.

.NOTES
    Author: Josh Block
    Date: 11.16.2026
    Type: Public
    Version: 1.1.0

.LINK
    https://github.com/j0shbl0ck
    https://learn.microsoft.com/en-us/graph/api/resources/booking-api-overview
    https://learn.microsoft.com/en-us/graph/permissions-reference
    https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.applications/new-mgapplication
    https://learn.microsoft.com/en-us/graph/api/oauth2permissiongrant-post
#>

# Run in PowerShell 5.1 or 7.
# Requires Microsoft.Graph.Authentication, Microsoft.Graph.Applications, Microsoft.Graph.Identity.SignIns.
# Run as Global Admin / Privileged Role Admin (needed to grant admin consent).

Clear-Host

#region Config
$GraphAppId       = "00000003-0000-0000-c000-000000000000"   # Microsoft Graph (well-known)
$DefaultAppName   = "Bookings-Management-App"
$DefaultSecretMos = 12

# Application (app-only) permission sets - used with the client secret
$PermissionSets = [ordered]@{
    "1" = @{ Name = "Read only";          Roles = @("Bookings.Read.All") }
    "2" = @{ Name = "Appointments R/W";   Roles = @("Bookings.Read.All", "BookingsAppointment.ReadWrite.All") }
    "3" = @{ Name = "Full read/write";    Roles = @("Bookings.ReadWrite.All") }
    "4" = @{ Name = "Full manage";        Roles = @("Bookings.Manage.All") }
}

# Delegated permissions - used by New-SharedBookingPage.ps1 (admin signs in through this app, no secret)
$DelegatedScopes = @("Bookings.Manage.All", "User.Read.All")
#endregion

#region Functions
function Write-Step    { param([string]$m) Write-Host "`n>> $m" -ForegroundColor Cyan }
function Write-Ok      { param([string]$m) Write-Host "   [OK]   $m" -ForegroundColor Green }
function Write-Warn    { param([string]$m) Write-Host "   [WARN] $m" -ForegroundColor Yellow }
function Write-Fail    { param([string]$m) Write-Host "   [FAIL] $m" -ForegroundColor Red }
function Write-DryRun  { param([string]$m) Write-Host "   [DRY]  $m" -ForegroundColor Magenta }
#endregion

#region Module check
Write-Step "Checking Microsoft Graph modules"
$Modules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.Applications", "Microsoft.Graph.Identity.SignIns")
foreach ($mod in $Modules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Fail "$mod is not installed. Run your module installer first."
        return
    }
    Write-Ok "$mod found"
}
Import-Module $Modules -ErrorAction Stop
#endregion

#region Prompts
Write-Host "`n=== Bookings Enterprise App Builder ===" -ForegroundColor White

$AppName = Read-Host "App display name [$DefaultAppName]"
if ([string]::IsNullOrWhiteSpace($AppName)) { $AppName = $DefaultAppName }

Write-Host "`nApplication (app-only) permission set:" -ForegroundColor White
foreach ($k in $PermissionSets.Keys) {
    Write-Host ("  {0}) {1,-18} {2}" -f $k, $PermissionSets[$k].Name, ($PermissionSets[$k].Roles -join ", "))
}
do { $choice = Read-Host "Select 1-4 [4]"; if (!$choice) { $choice = "4" } } until ($PermissionSets.Contains($choice))
$RequestedRoles = $PermissionSets[$choice].Roles

Write-Host "Delegated permissions (always added): $($DelegatedScopes -join ', ')" -ForegroundColor Gray

$SecretMonths = Read-Host "Client secret lifetime in months (1-24) [$DefaultSecretMos]"
if (-not ($SecretMonths -as [int]) -or [int]$SecretMonths -lt 1 -or [int]$SecretMonths -gt 24) { $SecretMonths = $DefaultSecretMos }
$SecretMonths = [int]$SecretMonths

$DryRun = (Read-Host "Dry run? No changes will be made (Y/N) [Y]") -notmatch '^[Nn]'
if ($DryRun) { Write-Host "`n*** DRY RUN MODE - nothing will be created ***" -ForegroundColor Magenta }
#endregion

#region Connect
Write-Step "Connecting to Microsoft Graph (delegated admin)"
try {
    Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "DelegatedPermissionGrant.ReadWrite.All" -NoWelcome -ErrorAction Stop
    $ctx = Get-MgContext
    $TenantId = $ctx.TenantId
    Write-Ok "Connected as $($ctx.Account) to tenant $TenantId"
}
catch {
    Write-Fail "Graph connection failed: $($_.Exception.Message)"
    return
}
#endregion

#region Resolve Graph permissions
Write-Step "Resolving Bookings permissions from the Microsoft Graph service principal"
try {
    $GraphSp = Get-MgServicePrincipal -Filter "appId eq '$GraphAppId'" -ErrorAction Stop
}
catch {
    Write-Fail "Could not read the Microsoft Graph service principal: $($_.Exception.Message)"
    return
}

# Application permissions (app roles)
$ResolvedRoles = @()
foreach ($roleName in $RequestedRoles) {
    $role = $GraphSp.AppRoles | Where-Object { $_.Value -eq $roleName -and $_.AllowedMemberTypes -contains "Application" }
    if ($role) { $ResolvedRoles += $role; Write-Ok "Application: $roleName -> $($role.Id)" }
    else       { Write-Warn "$roleName is not available as an application permission - skipping" }
}

# Delegated permissions (OAuth2 scopes)
$ResolvedScopes = @()
foreach ($scopeName in $DelegatedScopes) {
    $scope = $GraphSp.Oauth2PermissionScopes | Where-Object { $_.Value -eq $scopeName }
    if ($scope) { $ResolvedScopes += $scope; Write-Ok "Delegated:   $scopeName -> $($scope.Id)" }
    else        { Write-Warn "$scopeName is not available as a delegated permission - skipping" }
}

if (-not $ResolvedRoles -and -not $ResolvedScopes) {
    Write-Fail "No requested permissions could be resolved. Aborting."
    return
}
#endregion

#region Create app registration
Write-Step "Creating app registration '$AppName'"
$safeName = $AppName.Replace("'", "''")
$existing = Get-MgApplication -Filter "displayName eq '$safeName'" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Warn "An app named '$AppName' already exists (AppId $($existing[0].AppId))."
    if ((Read-Host "Use the existing app and update its configuration? (Y/N) [N]") -notmatch '^[Yy]') {
        Write-Host "Exiting without changes." -ForegroundColor Yellow
        return
    }
    $App = $existing | Select-Object -First 1
}

$ResourceAccess  = @($ResolvedRoles  | ForEach-Object { @{ Id = $_.Id; Type = "Role"  } })
$ResourceAccess += @($ResolvedScopes | ForEach-Object { @{ Id = $_.Id; Type = "Scope" } })
$RequiredResourceAccess = @(
    @{
        ResourceAppId  = $GraphAppId
        ResourceAccess = $ResourceAccess
    }
)

if ($DryRun) {
    if ($App) { Write-DryRun "Would update API permissions on $($App.AppId)" }
    else      { Write-DryRun "Would create app registration '$AppName' (single tenant)" }
}
else {
    try {
        if ($App) {
            Update-MgApplication -ApplicationId $App.Id -RequiredResourceAccess $RequiredResourceAccess -ErrorAction Stop
            Write-Ok "Updated API permissions on existing app"
        }
        else {
            $App = New-MgApplication -DisplayName $AppName `
                -SignInAudience "AzureADMyOrg" `
                -Notes "Microsoft Bookings management. App-only (secret) for administration; delegated for admin-run booking page creation. Created by $($ctx.Account) on $(Get-Date -Format 'MM.dd.yyyy')." `
                -RequiredResourceAccess $RequiredResourceAccess -ErrorAction Stop
            Write-Ok "Created app. AppId: $($App.AppId)"
        }
    }
    catch {
        Write-Fail "App registration failed: $($_.Exception.Message)"
        return
    }
}
#endregion

#region Configure interactive sign-in (redirect URIs)
Write-Step "Configuring Mobile and desktop sign-in for PowerShell"
if ($DryRun) {
    Write-DryRun "Would add redirect URIs: http://localhost, nativeclient, WAM broker"
}
else {
    $RedirectUris = @(
        "http://localhost",
        "https://login.microsoftonline.com/common/oauth2/nativeclient",
        "ms-appx-web://Microsoft.AAD.BrokerPlugin/$($App.AppId)"   # Windows sign-in broker (WAM)
    )
    try {
        Update-MgApplication -ApplicationId $App.Id -PublicClient @{ RedirectUris = $RedirectUris } -ErrorAction Stop
        $RedirectUris | ForEach-Object { Write-Ok $_ }
    }
    catch {
        Write-Fail "Redirect URI configuration failed: $($_.Exception.Message)"
    }
}
#endregion

#region Create enterprise app (service principal)
Write-Step "Creating enterprise application (service principal)"
if ($DryRun) {
    Write-DryRun "Would create service principal for '$AppName'"
}
else {
    try {
        $Sp = Get-MgServicePrincipal -Filter "appId eq '$($App.AppId)'" -ErrorAction SilentlyContinue
        if (-not $Sp) {
            $Sp = New-MgServicePrincipal -AppId $App.AppId -Tags "WindowsAzureActiveDirectoryIntegratedApp" -ErrorAction Stop
            Write-Ok "Service principal created. ObjectId: $($Sp.Id)"
            Start-Sleep -Seconds 10   # replication buffer before consent
        }
        else {
            Write-Ok "Service principal already exists. ObjectId: $($Sp.Id)"
        }
    }
    catch {
        Write-Fail "Service principal creation failed: $($_.Exception.Message)"
        return
    }
}
#endregion

#region Grant admin consent - application permissions
Write-Step "Granting admin consent for application permissions"
foreach ($role in $ResolvedRoles) {
    if ($DryRun) { Write-DryRun "Would grant $($role.Value)"; continue }
    try {
        $already = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $Sp.Id -All |
            Where-Object { $_.AppRoleId -eq $role.Id -and $_.ResourceId -eq $GraphSp.Id }
        if ($already) { Write-Ok "$($role.Value) already granted"; continue }

        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $Sp.Id `
            -PrincipalId $Sp.Id -ResourceId $GraphSp.Id -AppRoleId $role.Id -ErrorAction Stop | Out-Null
        Write-Ok "Granted $($role.Value)"
    }
    catch {
        Write-Fail "Consent for $($role.Value) failed: $($_.Exception.Message)"
    }
}
#endregion

#region Grant admin consent - delegated permissions
Write-Step "Granting tenant-wide admin consent for delegated permissions"
$ScopeString = ($ResolvedScopes | ForEach-Object Value) -join " "
if ($DryRun) {
    Write-DryRun "Would grant (all users): $ScopeString"
}
elseif ($ScopeString) {
    try {
        $grant = Get-MgOauth2PermissionGrant -Filter "clientId eq '$($Sp.Id)' and consentType eq 'AllPrincipals' and resourceId eq '$($GraphSp.Id)'" -ErrorAction Stop |
            Select-Object -First 1
        if ($grant) {
            $merged = (@($grant.Scope -split ' ') + @($ScopeString -split ' ') | Where-Object { $_ } | Sort-Object -Unique) -join " "
            Update-MgOauth2PermissionGrant -OAuth2PermissionGrantId $grant.Id -Scope $merged -ErrorAction Stop
            Write-Ok "Updated existing grant: $merged"
        }
        else {
            New-MgOauth2PermissionGrant -ClientId $Sp.Id -ConsentType "AllPrincipals" -ResourceId $GraphSp.Id -Scope $ScopeString -ErrorAction Stop | Out-Null
            Write-Ok "Granted: $ScopeString"
        }
    }
    catch {
        Write-Fail "Delegated consent failed: $($_.Exception.Message)"
    }
}
#endregion

#region Create client secret
Write-Step "Creating client secret ($SecretMonths months)"
$SecretValue = $null
$SecretEnd   = (Get-Date).AddMonths($SecretMonths)
if ($DryRun) {
    Write-DryRun "Would create secret expiring $($SecretEnd.ToString('MM.dd.yyyy'))"
}
else {
    try {
        $NewSecret = Add-MgApplicationPassword -ApplicationId $App.Id -PasswordCredential @{
            DisplayName = "Bookings-Secret-$(Get-Date -Format 'yyyyMMdd')"
            EndDateTime = $SecretEnd
        } -ErrorAction Stop
        $SecretValue = $NewSecret.SecretText
        Write-Ok "Secret created. Expires $($SecretEnd.ToString('MM.dd.yyyy'))"
    }
    catch {
        Write-Fail "Secret creation failed: $($_.Exception.Message)"
    }
}
#endregion

#region Summary
Write-Host "`n================ SUMMARY ================" -ForegroundColor White
Write-Host ("Tenant ID        : {0}" -f $TenantId)
Write-Host ("App name         : {0}" -f $AppName)
Write-Host ("Application ID   : {0}" -f $(if ($App) { $App.AppId } else { "<dry run>" }))
Write-Host ("App-only perms   : {0}" -f (($ResolvedRoles  | ForEach-Object Value) -join ", "))
Write-Host ("Delegated perms  : {0}" -f (($ResolvedScopes | ForEach-Object Value) -join ", "))
Write-Host ("Secret expires   : {0}" -f $SecretEnd.ToString('MM.dd.yyyy'))
if ($SecretValue) {
    Write-Host "Client secret    : $SecretValue" -ForegroundColor Yellow
    Write-Host "`nCopy the secret into your password vault now. It cannot be retrieved again." -ForegroundColor Yellow
}
Write-Host "`nNew-SharedBookingPage.ps1 needs only the Tenant ID and Application ID above (no secret)." -ForegroundColor Gray
Write-Host "=========================================" -ForegroundColor White

if (-not $DryRun -and $SecretValue -and (Read-Host "`nCopy secret to clipboard? (Y/N) [N]") -match '^[Yy]') {
    Set-Clipboard -Value $SecretValue
    Write-Ok "Secret copied to clipboard"
}

Disconnect-MgGraph | Out-Null
Write-Host "`nDone." -ForegroundColor Green
#endregion