<#
.SYNOPSIS
    <Provide a one-sentence description of what this script accomplishes.>

.DESCRIPTION
    <Optional detailed description explaining the purpose, behavior, and
    any important notes about usage.>

.NOTES
    Author: Josh Block
    Date: 11.26.2025
    Type: Public
    Version: <1.0.0>

.LINK
    https://github.com/j0shbl0ck
    <Add any relevant Microsoft Learn or documentation links here.>
#>

Make script that builds azure app

# Ensure you already have msGraph module(s) installed and up to date. Run in PowerShell 5

$ApplicationId = "xxxxxx-bece-x47-xxxxxx-xxxxxxxx"
$SecuredPassword = "xxxxxxxx~xxxxx9A4xxxxN"
$tenantID = "xxxxxxx-1xxx3-xxa-b25def-cxxxx3xf"

$SecuredPasswordPassword = ConvertTo-SecureString `
-String $SecuredPassword -AsPlainText -Force

$ClientSecretCredential = New-Object `
-TypeName System.Management.Automation.PSCredential `
-ArgumentList $ApplicationId, $SecuredPasswordPassword

Connect-MgGraph -TenantId $tenantID -ClientSecretCredential $ClientSecretCredential

# Get All Staff Members and their roles
$bookingBusinessId = "{username}@{domain}.onmicrosoft.com"

$staffMembers = Get-MgBookingBusinessStaffMember -BookingBusinessId $bookingBusinessId

foreach ($member in $staffMembers) {
    $memberDetails = $member.AdditionalProperties
    [PSCustomObject]@{
        Id          = $member.Id
        DisplayName = $memberDetails.displayName
        Email       = $memberDetails.emailAddress
        Role        = $memberDetails.role
    }
}