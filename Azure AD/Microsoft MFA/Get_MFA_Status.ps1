<#
.SYNOPSIS
    This script pulls information on whether a user has MFA enabled or not. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.1.3
    Date: 03.23.22
    Type: Public
.NOTES
    You may need to resize the console window varying on email address length.
.LINK
    Source: https://dailysysadmin.com/KB/Article/3725/use-powershell-to-get-the-mfa-enabled-or-disabled-status-of-office-365-and-azure-users-and-type-of-mfa-used/
#>

Clear-Host

# Enter global admin credentials
Connect-MsolService

## VARIABLES ##
$Users = Get-MsolUser -All | Where-Object { $_.UserType -ne "Guest" }
$report = [System.Collections.Generic.List[Object]]::new()

# Finds user count in Azure Active Directory
Write-Host -ForegroundColor Yellow "Retrieving user count from Azure AD..."
Write-Host -ForegroundColor Green $User.Count "users found.`n"

# Retrieve the MFA status for each user

ForEach ($User in $Users) {
    $MFAEnforced = $User.StrongAuthenticationRequirements.State
    $MFAPhone = $User.StrongAuthenticationUserDetails.PhoneNumber
    $DefaultMFAMethod = ($User.StrongAuthenticationMethods | Where-Object { $_.IsDefault -eq "True" }).MethodType
    If (($MFAEnforced -eq "Enforced") -or ($MFAEnforced -eq "Enabled")) {
        Switch ($DefaultMFAMethod) {
            "OneWaySMS" { $MethodUsed = "One-way SMS" }
            "TwoWayVoiceMobile" { $MethodUsed = "Phone call verification" }
            "PhoneAppOTP" { $MethodUsed = "Hardware token or authenticator app" }
            "PhoneAppNotification" { $MethodUsed = "Authenticator app" }
        }
    }
    Else {
        $MFAEnforced = "Not Enabled"
        $MethodUsed = "MFA Not Used" 
    }
  
    $ReportLine = [PSCustomObject] @{
        User        = $User.UserPrincipalName
        Name        = $User.DisplayName
        MFAUsed     = $MFAEnforced
        MFAMethod   = $MethodUsed 
        PhoneNumber = $MFAPhone
    }
                 
    $Report.Add($ReportLine) 
}

$desktop = [Environment]::GetFolderPath("Desktop")
$exportPath = $desktop + "\UserMFAStatus.csv"
Write-Host "Report is in $exportPath"
$Report | Select-Object User, Name, MFAUsed, MFAMethod, PhoneNumber | Sort-Object Name | Out-GridView
$Report | Sort-Object Name | Export-Csv -Path $exportPath -NoTypeInformation

