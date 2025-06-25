<#
.SYNOPSIS
    Creates editor-level calendar permissions between all licensed users in Microsoft 365 using Microsoft Graph.
.DESCRIPTION
    This script builds a fully-connected calendar permission mesh by granting each licensed mailbox user "Editor" access 
    to every other licensed user's primary calendar. It uses Microsoft Graph PowerShell SDK and supports validation 
    to ensure each user has the expected number of permissions.

    Author: j0shbl0ck (https://github.com/j0shbl0ck)
    Version: 1.0.4
    Date: 06.24.25
    Type: Public
.EXAMPLE
    .\New-FullCalendarMesh.ps1
    Connects to Microsoft Graph, gathers all licensed users, assigns calendar permissions, and validates access mesh.
.NOTES
    Prerequisites:
    - Microsoft Graph PowerShell SDK [Install-Module Microsoft.Graph -Scope CurrentUser]
    - App registration or delegated Graph access with Calendars.ReadWrite and User.Read.All
    - Admin consent must be granted for required Graph scopes
#>

param (
    [string]$ClientId = "xxxxxxx-f83a-4ed9-xxxx-xxxxxx",
    [string]$TenantId = "xxxxxxxx-591x-xxxx-xxxx-46axx76xxxe1",
    [string]$ClientSecret = "xxxxx~xxxxxx~xxxxxxxxxxxxx"
)

# Increase the Function Count
$MaximumFunctionCount = 8192
# Increase the Variable Count
$MaximumVariableCount = 8192

function Test-RunningAsAdministrator {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "Not running as administrator. Re-launch script with elevated privileges..." -ForegroundColor Yellow
        # Pause for user to read the message
        Start-Sleep -Seconds 3
        exit
    }
}

function Install-GraphModule {
    $requiredGraphVersion = [version]"2.28.0"
    $installedGraph = Get-InstalledModule -Name Microsoft.Graph -ErrorAction SilentlyContinue

    if (-not $installedGraph) {
        Write-Warning "Microsoft.Graph module is not installed. Installing it now..."
        Install-Module Microsoft.Graph -Scope CurrentUser -Force
    }
    elseif ($installedGraph.Version -lt $requiredGraphVersion) {
        Write-Warning "Microsoft.Graph version $($installedGraph.Version) is below required $requiredGraphVersion. Updating..."
        Update-Module Microsoft.Graph -Force
    } else {
        Write-Host "Microsoft.Graph version $($installedGraph.Version) meets the requirement ($requiredGraphVersion)." -ForegroundColor Green
    }
    Import-Module Microsoft.Graph.Users -ErrorAction Stop
}

function Connect-ToGraph {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
<#     #Convert the Client Secret to a Secure String
    $SecureClientSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force

    # Create a PSCredential Object Using the Client ID and Secure Client Secret
    $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $SecureClientSecret

    Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential -ErrorAction Stop #>
    # Connect to API
    $request = @{
        Method = 'POST'
        URI    = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        body   = @{
            grant_type    = "client_credentials"
            scope         = "https://graph.microsoft.com/.default"
            client_id     = $ClientId
            client_secret = $ClientSecret
        }
    }
    $token = ConvertTo-SecureString -String (Invoke-RestMethod @request).access_token -AsPlainText -Force
    Connect-MgGraph -AccessToken $token
        
}

function Get-LicensedUsers {
    Write-Host "Retrieving licensed users..." -ForegroundColor Yellow
    $allUsers = Get-MgUser -All -Property "UserPrincipalName,AssignedLicenses"
    return $allUsers | Where-Object { $_.AssignedLicenses.Count -gt 0 } | Select-Object -ExpandProperty UserPrincipalName
}

function Grant-CalendarPermissions {
    param (
        [string[]]$UserList,
        [ref]$LogRef
    )

    $totalUsers = $UserList.Count
    $counter = 0

    foreach ($user in $UserList) {
        $counter++
        $percentComplete = [math]::Round(($counter / $totalUsers) * 100)
        Write-Progress -Activity "Setting Calendar Defaults" -Status "Processing $user" -PercentComplete $percentComplete

        try {
            # Get user's default calendar
            $defaultCalendar = Get-MgUserCalendar -UserId $user | Where-Object { $_.IsDefaultCalendar -eq $true } | Select-Object -First 1
            if (-not $defaultCalendar) {
                throw "No default calendar found for $user"
            }

            $calendarId = $defaultCalendar.Id

            # Get all calendar permissions
            $permissions = Get-MgUserCalendarPermission -UserId $user -CalendarId $calendarId -ErrorAction Stop

            # Find "My Organization" permission entry
            $defaultPerm = $permissions | Where-Object { $_.EmailAddress.Name -eq "My Organization" }
            if (-not $defaultPerm) {
                throw "'My Organization' default permission not found for $user"
            }

            $permId = $defaultPerm.Id

            # Update "My Organization" to write access
            Update-MgUserCalendarPermission -UserId $user -CalendarId $calendarId -CalendarPermissionId $permId -BodyParameter @{
                Role = "write"
            } | Out-Null

            Write-Host "✔ ${user}: 'My Organization' permission set to 'write'" -ForegroundColor Green
            $LogRef.Value += [PSCustomObject]@{
                User   = $user
                Status = "Success"
                Role   = "write"
                Error  = ""
            }

        } catch {
            Write-Warning "Failed to update calendar permission for ${user}: $_"
            $LogRef.Value += [PSCustomObject]@{
                User   = $user
                Status = "Failed"
                Role   = "N/A"
                Error  = $_.Exception.Message
            }
        }
    }
}

function Test-UserPermissions {
    param (
        [string]$User,
        [ref]$LogRef
    )

    try {
        # Get the user's default calendar
        $defaultCalendar = Get-MgUserCalendar -UserId $User | Where-Object { $_.IsDefaultCalendar -eq $true } | Select-Object -First 1
        if (-not $defaultCalendar) {
            throw "No default calendar found for $User"
        }

        $calendarId = $defaultCalendar.Id

        # Get current permissions
        $permissions = Get-MgUserCalendarPermission -UserId $User -CalendarId $calendarId -ErrorAction Stop
        $defaultPerm = $permissions | Where-Object { $_.EmailAddress.Name -eq "My Organization" }

        if (-not $defaultPerm) {
            throw "'My Organization' permission not found for $User"
        }

        if ($defaultPerm.Role -eq "write") {
            Write-Host "✔ ${User} validated: 'My Organization' permission is 'write'" -ForegroundColor Green
            $LogRef.Value += [PSCustomObject]@{
                User   = $User
                Status = "Validated"
                Role   = $defaultPerm.Role
                Error  = ""
            }
        } else {
            Write-Warning "${User}: 'My Organization' permission is '$($defaultPerm.Role)', expected 'write'"
            $LogRef.Value += [PSCustomObject]@{
                User   = $User
                Status = "Mismatch"
                Role   = $defaultPerm.Role
                Error  = "Expected 'write'"
            }
        }

    } catch {
        Write-Warning "Validation failed for ${User}: $_"
        $LogRef.Value += [PSCustomObject]@{
            User   = $User
            Status = "Validation Error"
            Role   = "N/A"
            Error  = $_.Exception.Message
        }
    }
}

function Main {
    Test-RunningAsAdministrator
    Install-GraphModule
    Connect-ToGraph
    Clear-Host

    $userList = Get-LicensedUsers
    $totalUsers = $userList.Count
    Write-Host "Total licensed users: $totalUsers" -ForegroundColor Green

    $log = @()
    Grant-CalendarPermissions -UserList $userList -LogRef ([ref]$log)

    # Export Log to User's Download folder.
    $log | Export-Csv -Path "$HOME\Downloads\CalendarPermissionLog.csv" -NoTypeInformation -Encoding UTF8
    Write-Host "`nScript complete. Log saved to $HOME\Downloads\CalendarPermissionLog.csv" -ForegroundColor Cyan
}

# Execute
Main
