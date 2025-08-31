<#
.SYNOPSIS
    This script checks for expired or expiring certificates in both
    the Computer and User certificate stores within a defined number of days.
    Default is 14 days.

.DESCRIPTION
    The script enumerates certificates from the Cert:\ drive and identifies
    any certificates expiring within the specified number of days. Results are
    displayed in a table with details such as store, subject, issuer, and
    thumbprint.

.PARAMETER Days
    Number of days to check ahead for expiring certificates. Default is 14.

.OUTPUTS
    Table of certificates with expiration details if any are found.
    If none are found, a success message is displayed.

.NOTES
    Author: Josh Block
    Version: 1.0.0
    Date: 08.31.25
    Type: Public

.LINK
    https://github.com/j0shbl0ck
#>

param (
    [Parameter(Mandatory = $false)][int]$Days = 14
)

#Create a list of certificates for both Computer and User Account expiring in $days
$ExperingCerts = foreach ($Certificate in (Get-ChildItem Cert:).Location ) {
    foreach ($ExpiringCert in Get-ChildItem -Path "Cert:\$($Certificate)\My" | Where-Object NotAfter -LT (Get-Date).AddDays("$($Days)")) {
        [PSCustomObject]@{
            Store            = $Certificate
            DaysUntilExpired = ($ExpiringCert.NotAfter - (Get-Date)).Days
            ExpirationDate   = $ExpiringCert.NotAfter
            Friendlyname     = if ($Expiringcert.FriendlyName) { $ExperingCert.FriendlyName } else { "<None" }
            Issuer           = $ExpiringCert.Issuer
            Subject          = $Expiringcert.Subject.Split('=,')[1]
            ThumbPrint       = $ExpiringCert.Thumbprint
        }
    }
}

#Output to screen if found
if ($ExperingCerts) {
    Write-Warning ("Expired/Expering Certificates found!")
    $ExperingCerts | Sort-Object ExpirationDate | Format-Table -AutoSize
}
else {
    Write-Host ("No expired/expiring Certificates found") -ForegroundColor Green
}