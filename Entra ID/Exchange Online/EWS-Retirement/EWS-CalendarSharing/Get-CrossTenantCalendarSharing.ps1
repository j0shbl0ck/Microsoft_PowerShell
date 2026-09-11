<#
.SYNOPSIS
    Reports cross-tenant calendar sharing configuration in Exchange Online —
    Organization Relationships and Sharing Policies — including partner
    domains and Free/Busy access level.

.DESCRIPTION
    Enumerates Get-OrganizationRelationship and Get-SharingPolicy to answer
    "is cross-tenant calendar sharing enabled, and with whom?"

    Useful ahead of the EWS deprecation (Oct 1, 2026) migration to Microsoft
    365 Cross-Tenant Access Policies — Organization Relationships are the
    legacy federation trust objects that currently carry EWS-based Free/Busy,
    MailTips, and calendar sharing to partner tenants. This script inventories
    what's currently configured so you know what needs to be re-created as
    Cross-Tenant Access Policy configs before removal.

    This script is READ-ONLY. It makes no configuration changes.

.PARAMETER Detailed
    Include the raw Organization Relationship object (full property set,
    including delegation/federation XML) in the returned objects.

.PARAMETER ExportPath
    Optional path to export the combined results as CSV, e.g.
    -ExportPath "C:\Reports\CrossTenantSharing.csv"

.EXAMPLE
    .\Get-CrossTenantCalendarSharing.ps1

.EXAMPLE
    .\Get-CrossTenantCalendarSharing.ps1 -ExportPath ".\sharing-report.csv"

.NOTES
    Author:   Josh Block (j0shbl0ck)
    Version:  1.0.0
    Repo:     https://github.com/j0shbl0ck
    Requires: ExchangeOnlineManagement module, an active Connect-ExchangeOnline session
    Scope:    Fully cloud-hosted cross-tenant only. Hybrid on-prem <-> EOL
              federation trusts will also show up here as Organization
              Relationships but are OUT of scope for the EWS deprecation itself
              — don't assume every enabled relationship needs migrating.
#>

[CmdletBinding()]
param(
    [switch]$Detailed,
    [string]$ExportPath
)

#region Connection Check
try {
    $null = Get-ConnectionInformation -ErrorAction Stop
}
catch {
    Write-Host "Not connected to Exchange Online. Connecting now..." -ForegroundColor Yellow
    Connect-ExchangeOnline -ShowBanner:$false
}
#endregion

#region Organization Relationships (cross-tenant federation trusts)
Write-Host "`n=== Organization Relationships ===" -ForegroundColor Cyan

$orgRelationships = Get-OrganizationRelationship

if (-not $orgRelationships) {
    Write-Host "No organization relationships found." -ForegroundColor Yellow
}

$orgResults = foreach ($rel in $orgRelationships) {
    $status = if ($rel.Enabled) { "Enabled" } else { "Disabled" }
    $color  = if ($rel.Enabled) { "Green" } else { "DarkGray" }

    Write-Host "`n$($rel.Name)" -ForegroundColor White
    Write-Host "  Status:            $status" -ForegroundColor $color
    Write-Host "  Domains:           $($rel.DomainNames -join ', ')"
    Write-Host "  Free/Busy Access:  $($rel.FreeBusyAccessEnabled)  (Level: $($rel.FreeBusyAccessLevel))"
    Write-Host "  MailTips Access:   $($rel.MailTipsAccessEnabled)  (Level: $($rel.MailTipsAccessLevel))"
    Write-Host "  Archive Access:    $($rel.ArchiveAccessEnabled)"
    Write-Host "  Delegation Trust:  $($rel.DelegationTrustLink)"

    [PSCustomObject]@{
        Type            = "OrganizationRelationship"
        Name            = $rel.Name
        Enabled         = $rel.Enabled
        Domains         = ($rel.DomainNames -join '; ')
        FreeBusyEnabled = $rel.FreeBusyAccessEnabled
        FreeBusyLevel   = $rel.FreeBusyAccessLevel
        MailTipsEnabled = $rel.MailTipsAccessEnabled
        MailTipsLevel   = $rel.MailTipsAccessLevel
        ArchiveAccess   = $rel.ArchiveAccessEnabled
        RawObject       = if ($Detailed) { $rel } else { $null }
    }
}
#endregion

#region Sharing Policies (individual calendar sharing to external domains/anonymous)
Write-Host "`n=== Sharing Policies ===" -ForegroundColor Cyan

$sharingPolicies = Get-SharingPolicy

$sharingResults = foreach ($policy in $sharingPolicies) {
    $status = if ($policy.Enabled) { "Enabled" } else { "Disabled" }
    $color  = if ($policy.Enabled) { "Green" } else { "DarkGray" }

    Write-Host "`n$($policy.Name)" -ForegroundColor White
    Write-Host "  Status:  $status" -ForegroundColor $color
    Write-Host "  Default: $($policy.Default)"
    Write-Host "  Domains/Rules:"
    foreach ($d in $policy.Domains) {
        Write-Host "    - $d" -ForegroundColor Gray
    }

    [PSCustomObject]@{
        Type    = "SharingPolicy"
        Name    = $policy.Name
        Enabled = $policy.Enabled
        Default = $policy.Default
        Domains = ($policy.Domains -join '; ')
    }
}
#endregion

#region Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$enabledOrgRels = ($orgResults | Where-Object Enabled).Count
$enabledSharing = ($sharingResults | Where-Object Enabled).Count
Write-Host "Enabled Organization Relationships: $enabledOrgRels of $($orgResults.Count)"
Write-Host "Enabled Sharing Policies:            $enabledSharing of $($sharingResults.Count)"
Write-Host "`nNo changes were made — this script is read-only." -ForegroundColor DarkGray
#endregion

#region Export
if ($ExportPath) {
    $allResults = @($orgResults | Select-Object * -ExcludeProperty RawObject) + $sharingResults
    $allResults | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "`nExported results to $ExportPath" -ForegroundColor Green
}
#endregion
