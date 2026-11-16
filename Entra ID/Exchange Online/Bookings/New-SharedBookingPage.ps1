<#
.SYNOPSIS
    Creates a shared Microsoft Bookings page and assigns two or more administrators by UPN lookup.

.NOTES
    Author: Josh Block
    Date: 11.16.2026
    Type: Public
    Version: 1.2.0

.LINK
    https://github.com/j0shbl0ck
    https://learn.microsoft.com/en-us/graph/api/bookingbusiness-post-bookingbusinesses
    https://learn.microsoft.com/en-us/graph/api/bookingbusiness-post-staffmembers
    https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.bookings/new-mgbookingbusiness
#>

# Run as an M365 Administration Team member (must have Bookings creation rights via OWA mailbox policy).
# Creating a booking page requires DELEGATED Bookings.Manage.All - app-only is not supported by Microsoft.
# Signs in through the Bookings enterprise app (built by New-BookingsEnterpriseApp.ps1 v1.1.0+), which has
# delegated permissions pre-consented, so users get a normal sign-in with no consent prompt.
# The person running this needs a license with the Microsoft Bookings service plan enabled.
# Requires Microsoft.Graph.Authentication, Microsoft.Graph.Bookings, Microsoft.Graph.Users.

Clear-Host

#region Config
$StaffTimeZone         = "Central Standard Time"
$RemoveRunnerFromStaff = $false      # $true = remove the person running the script if they were auto-added and aren't one of the admins
$PublishOnCreate       = $false      # $true = publish immediately (usually leave off so admins can add services first)
$MaxRetries            = 6           # retries while the new booking mailbox provisions
$RetryDelaySeconds     = 15
#endregion

#region Functions
function Write-Step   { param([string]$m) Write-Host "`n>> $m" -ForegroundColor Cyan }
function Write-Ok     { param([string]$m) Write-Host "   [OK]   $m" -ForegroundColor Green }
function Write-Warn   { param([string]$m) Write-Host "   [WARN] $m" -ForegroundColor Yellow }
function Write-Fail   { param([string]$m) Write-Host "   [FAIL] $m" -ForegroundColor Red }

function Resolve-AdminUser {
    param([string]$Label)
    while ($true) {
        $upn = (Read-Host "$Label UPN").Trim()
        if ([string]::IsNullOrWhiteSpace($upn)) { Write-Warn "UPN cannot be blank."; continue }
        try {
            $u = Get-MgUser -UserId $upn -Property Id, DisplayName, Mail, UserPrincipalName, AccountEnabled -ErrorAction Stop
            if (-not $u.AccountEnabled) { Write-Warn "$upn is disabled. Enter a different user."; continue }
            if (-not $u.Mail)           { Write-Warn "$upn has no mailbox/mail address. Enter a different user."; continue }
            Write-Ok "$($u.DisplayName) <$($u.Mail)>"
            return $u
        }
        catch {
            Write-Warn "User '$upn' not found. Try again."
        }
    }
}

function Invoke-WithRetry {
    param([scriptblock]$Action, [string]$What)
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try { return & $Action }
        catch {
            if ($i -eq $MaxRetries) { throw }
            Write-Warn "$What not ready yet (attempt $i/$MaxRetries). Waiting $RetryDelaySeconds sec..."
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }
}
#endregion

#region Module check
Write-Step "Checking Microsoft Graph modules"
foreach ($mod in @("Microsoft.Graph.Authentication", "Microsoft.Graph.Bookings", "Microsoft.Graph.Users")) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Fail "$mod is not installed. Run your module installer first."
        return
    }
    Write-Ok "$mod found"
}
Import-Module Microsoft.Graph.Authentication, Microsoft.Graph.Bookings, Microsoft.Graph.Users -ErrorAction Stop
#endregion

#region Connect
Write-Host "`n=== Connect through the Bookings enterprise app ===" -ForegroundColor White
Write-Host "Use the Tenant ID and Application ID from New-BookingsEnterpriseApp.ps1 (no secret needed)." -ForegroundColor Gray

$GuidPattern = '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$'
do {
    $TenantId = (Read-Host "Tenant ID").Trim()
    if ($TenantId -notmatch $GuidPattern) { Write-Warn "Tenant ID must be a GUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)." }
} until ($TenantId -match $GuidPattern)
do {
    $AppId = (Read-Host "Application (client) ID").Trim()
    if ($AppId -notmatch $GuidPattern) { Write-Warn "Application ID must be a GUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)." }
} until ($AppId -match $GuidPattern)

Write-Step "Signing in to Microsoft Graph (delegated, through app $AppId)"
try {
    Connect-MgGraph -ClientId $AppId -TenantId $TenantId -Scopes "Bookings.Manage.All", "User.Read.All" -NoWelcome -ErrorAction Stop
    $ctx = Get-MgContext
    if ($ctx.AuthType -ne "Delegated") {
        Write-Fail "Connected as app-only. Booking pages can only be created by a signed-in user. Aborting."
        Disconnect-MgGraph | Out-Null
        return
    }
    Write-Ok "Connected as $($ctx.Account) via $($ctx.AppName)"
}
catch {
    Write-Fail "Graph connection failed: $($_.Exception.Message)"
    return
}
#endregion

#region Prompts
Write-Host "`n=== Shared Booking Page Builder ===" -ForegroundColor White

do {
    $PageName = (Read-Host "Booking page name").Trim()
} until (-not [string]::IsNullOrWhiteSpace($PageName))

Write-Step "Looking up administrators"
$Admins = [System.Collections.Generic.List[object]]::new()

# Two admins required, then optional extras
$n = 1
while ($true) {
    if ($n -gt 2) {
        if ((Read-Host "Add another admin? (Y/N) [N]") -notmatch '^[Yy]') { break }
    }
    $candidate = Resolve-AdminUser -Label "Admin $n"
    if ($Admins.Id -contains $candidate.Id) {
        Write-Warn "$($candidate.DisplayName) is already in the admin list. Enter a different user."
        continue
    }
    $Admins.Add($candidate)
    $n++
}
$Admin1 = $Admins[0]
#endregion

#region Duplicate check
Write-Step "Checking for an existing page named '$PageName'"
# Booking pages are backed by a mailbox account in Entra ID, so check the directory
# instead of listing booking businesses (that call can return "Forbidden Access" under delegated auth).
try {
    $safeName = $PageName.Replace("'", "''")
    $existing = Get-MgUser -Filter "displayName eq '$safeName'" -Property Id, DisplayName, Mail, UserPrincipalName -All -ErrorAction Stop
    if ($existing) {
        Write-Fail "An account named '$PageName' already exists ($(($existing | Select-Object -First 1).UserPrincipalName)). Choose a different name. Aborting."
        return
    }
    Write-Ok "Name is available"
}
catch {
    Write-Warn "Could not check the directory for '$PageName': $($_.Exception.Message). Continuing."
}
#endregion

#region Confirm
Write-Host "`n--------------- REVIEW ---------------" -ForegroundColor White
Write-Host "Page name : $PageName"
for ($i = 0; $i -lt $Admins.Count; $i++) {
    Write-Host ("Admin {0,-4}: {1} <{2}>" -f ($i + 1), $Admins[$i].DisplayName, $Admins[$i].Mail)
}
Write-Host "Publish   : $PublishOnCreate"
Write-Host "--------------------------------------" -ForegroundColor White
if ((Read-Host "Create this booking page? (Y/N) [N]") -notmatch '^[Yy]') {
    Write-Host "Cancelled. No changes made." -ForegroundColor Yellow
    return
}
#endregion

#region Create booking page
Write-Step "Creating booking page '$PageName'"
try {
    $Business = New-MgBookingBusiness -BodyParameter @{
        displayName        = $PageName
        email              = $Admin1.Mail
        defaultCurrencyIso = "USD"
    } -ErrorAction Stop
    $BusinessId = $Business.Id
    Write-Ok "Created. Booking ID / mailbox: $BusinessId"
}
catch {
    Write-Fail "Booking page creation failed: $($_.Exception.Message)"
    Write-Host "   Check that $($ctx.Account) has Bookings creation rights (OWA mailbox policy)." -ForegroundColor Yellow
    return
}
#endregion

#region Inspect auto-added staff
Write-Step "Checking staff that Bookings added automatically"
$Staff = @()
try {
    $Staff = Invoke-WithRetry -What "Booking mailbox" -Action {
        Get-MgBookingBusinessStaffMember -BookingBusinessId $BusinessId -All -ErrorAction Stop
    }
}
catch {
    Write-Warn "Could not read staff list: $($_.Exception.Message)"
}

$RunnerStaff = $Staff | Where-Object { $_.AdditionalProperties.emailAddress -eq $ctx.Account }
if ($RunnerStaff) {
    Write-Ok "$($ctx.Account) was auto-added as '$($RunnerStaff.AdditionalProperties.role)'"
}
else {
    Write-Ok "$($ctx.Account) was NOT auto-added to staff"
}
#endregion

#region Add administrators
Write-Step "Adding administrators"
foreach ($a in $Admins) {
    $match = $Staff | Where-Object { $_.AdditionalProperties.emailAddress -eq $a.Mail }
    if ($match) {
        if ($match.AdditionalProperties.role -ne "administrator") {
            try {
                Update-MgBookingBusinessStaffMember -BookingBusinessId $BusinessId -BookingStaffMemberBaseId $match.Id -BodyParameter @{
                    "@odata.type" = "#microsoft.graph.bookingStaffMember"
                    role          = "administrator"
                } -ErrorAction Stop
                Write-Ok "$($a.DisplayName) promoted to administrator"
            }
            catch { Write-Fail "Could not promote $($a.DisplayName): $($_.Exception.Message)" }
        }
        else { Write-Ok "$($a.DisplayName) is already an administrator" }
        continue
    }

    try {
        Invoke-WithRetry -What "Staff add for $($a.DisplayName)" -Action {
            New-MgBookingBusinessStaffMember -BookingBusinessId $BusinessId -BodyParameter @{
                "@odata.type"              = "#microsoft.graph.bookingStaffMember"
                displayName                = $a.DisplayName
                emailAddress               = $a.Mail
                role                       = "administrator"
                timeZone                   = $StaffTimeZone
                useBusinessHours           = $true
                isEmailNotificationEnabled = $true
            } -ErrorAction Stop
        } | Out-Null
        Write-Ok "$($a.DisplayName) added as administrator"
    }
    catch {
        Write-Fail "Could not add $($a.DisplayName): $($_.Exception.Message)"
    }
}
#endregion

#region Optional: remove runner
$RunnerIsAdmin = $Admins.Mail -contains $ctx.Account -or $Admins.UserPrincipalName -contains $ctx.Account
if ($RemoveRunnerFromStaff -and $RunnerStaff -and -not $RunnerIsAdmin) {
    Write-Step "Removing $($ctx.Account) from staff"
    try {
        Remove-MgBookingBusinessStaffMember -BookingBusinessId $BusinessId -BookingStaffMemberBaseId $RunnerStaff.Id -ErrorAction Stop
        Write-Ok "Removed"
    }
    catch { Write-Fail "Could not remove runner: $($_.Exception.Message)" }
}
#endregion

#region Optional: publish
if ($PublishOnCreate) {
    Write-Step "Publishing booking page"
    try {
        Publish-MgBookingBusiness -BookingBusinessId $BusinessId -ErrorAction Stop
        Write-Ok "Published"
    }
    catch { Write-Fail "Publish failed: $($_.Exception.Message)" }
}
#endregion

#region Summary
Write-Step "Final staff list"
try {
    Get-MgBookingBusinessStaffMember -BookingBusinessId $BusinessId -All -ErrorAction Stop | ForEach-Object {
        [PSCustomObject]@{
            DisplayName = $_.AdditionalProperties.displayName
            Email       = $_.AdditionalProperties.emailAddress
            Role        = $_.AdditionalProperties.role
        }
    } | Format-Table -AutoSize
}
catch { Write-Warn "Could not read final staff list: $($_.Exception.Message)" }

Write-Host "================ SUMMARY ================" -ForegroundColor White
Write-Host "Page name  : $PageName"
Write-Host "Booking ID : $BusinessId"
Write-Host "Admins     : $(($Admins | ForEach-Object Mail) -join ', ')"
Write-Host "Published  : $PublishOnCreate"
Write-Host "=========================================" -ForegroundColor White

Disconnect-MgGraph | Out-Null
Write-Host "`nDone." -ForegroundColor Green
#endregion