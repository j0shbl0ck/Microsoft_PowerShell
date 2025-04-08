<#
.SYNOPSIS
    This script will prompt for the username of a user and then do the following:
    - Roll user password
    - Block user from signing in to Microsoft
    - Revoke current signins from user
This can be used in an emergency where a user account is compromised.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 04.08.25
    Type: Private
.NOTES
    This script it built for the Datto RMM platform and could be used for Intune. 
.LINK
    https://helpx.adobe.com/acrobat/kb/download-64-bit-installer.html
    https://get.adobe.com/reader/enterprise/
#>

# Set variables for the Microsoft Graph connection
param (
    [string]$TenantId = "xxx-xxx-xxx-xxx-xxxxxx"
)

# Authenticate with Microsoft Graph
Write-Host -ForegroundColor Yellow "Authenticating with Microsoft Graph..."

try {
    $app = Connect-MgGraph -TenantId $TenantId -Scopes User.ReadWrite.All,Directory.AccessAsUser.All -ErrorAction Stop

    if (!$App) {
        Write-Host -ForegroundColor Red "Authentication failed. No application object returned."
        exit
    }

    Write-Host -ForegroundColor Green "Successfully authenticated with Microsoft Graph.`n"
}
catch {
    # Capture the error and log it
    Write-Host -ForegroundColor Red "Authentication failed. Error: $_"
    exit
}

# Import Microsoft Graph module
Import-Module Microsoft.Graph.Users

$userName = Read-Host "UPN of User"

# Generate random password
$passwd = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 12 | ForEach-Object {[char]$_})

$params = @{
    # passwordProfile resource
	passwordProfile = @{
        # passwordProfile properties
		forceChangePasswordNextSignIn = $True
		password = "${passwd}"
	}
    # accountEnbaled string request
    accountEnabled = $False
}
# Show the generated password
Write-Host -ForegroundColor Magenta "Generated Password: $passwd"
Write-Host -ForegroundColor Yellow "Changing password. Disabling Account. Revoking Sessions...`n"

Update-MgUser -UserId $userName -BodyParameter $params
Revoke-MgUserSignInSession -UserId $userName

$userInfo = Get-MgUser -UserId $username -Property accountEnabled,lastPasswordChangeDateTime | Select-Object accountEnabled,lastPasswordChangeDateTime

# Display user account status and last password change time
Write-Host -ForegroundColor Green "User account status: $($userInfo.accountEnabled)"
# Display user account last password change time in CST format
if ($userInfo.lastPasswordChangeDateTime) {
    $lastChange = [DateTime]::Parse($userInfo.lastPasswordChangeDateTime).ToLocalTime()
    Write-Host -ForegroundColor Green "Last password change (CST): $($lastChange.ToString('yyyy-MM-dd HH:mm:ss'))`n"
} else {
    Write-Host -ForegroundColor Yellow "No password change history available.`n"
}

# Disconnect from Microsoft Graph
Write-Host -ForegroundColor Green "Disconnecting from Microsoft Graph."
Disconnect-MgGraph | Out-Null