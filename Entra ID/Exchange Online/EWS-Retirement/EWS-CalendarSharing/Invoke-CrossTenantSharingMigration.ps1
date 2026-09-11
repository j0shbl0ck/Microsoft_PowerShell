<#
.SYNOPSIS
    Toolkit for migrating Exchange Online cross-tenant Free/Busy, MailTips,
    and Calendar Sharing configurations to Microsoft 365 Cross-Tenant Access
    Policy (XTAP), ahead of the EWS deprecation.

.DESCRIPTION
    Templated against Microsoft's migration guide:
    https://learn.microsoft.com/en-us/exchange/sharing/migrate-to-m365-xtap

    Covers the full lifecycle for both legacy configuration types:

        Organization Relationships (Free/Busy, MailTips)
          Inventory -> EstablishTrust -> GrantCapability -> DisableRelationship
          (test) -> ReenableRelationship (if needed) -> RemoveRelationship

        Sharing Policies (Calendar Sharing -- wildcard, domain-specific, or anonymous)
          Inventory -> CheckPolicyAssignment -> GrantCapability (-Anonymous or
          -TenantId as applicable) -> DisableSharingPolicy (test) ->
          ReenableSharingPolicy (if needed) -> RemoveSharingPolicy

    Nothing about a specific organization, vendor, or tenant is hardcoded --
    every target (relationship name, policy name, tenant ID, capability
    level) is passed in as a parameter, so this runs unmodified against any
    tenant's inventory.

    Run one -Phase at a time and confirm results before moving to the next.
    Everything that writes configuration supports -WhatIf.

.PARAMETER Phase
    Which step to execute:
        Inventory              - Lists all Organization Relationships and Sharing Policies,
                                  with Enabled/FreeBusy/MailTips/domain detail
        CheckPolicyAssignment  - Reports how many mailboxes are assigned to each Sharing Policy
                                  (server-scoped with -RecipientTypeDetails; use -PolicyName to
                                  also list matching mailboxes individually)
        GuestReview            - Reports last sign-in for guest users matching -DomainFilter,
                                  to help assess whether a relationship is still in active use
        EstablishTrust         - Creates the Entra XTAP partner trust for -TenantId
                                  (once per partner organization)
        GrantCapability        - Grants a Free/Busy, MailTips, or Calendar Sharing capability.
                                  Scope is inferred from parameters:
                                    -TenantId given            -> partner-specific
                                    -Anonymous switch given    -> anonymous (default policy only)
                                    neither given               -> default policy (wildcard/org-wide)
        DisableRelationship    - Disables an Organization Relationship for side-by-side XTAP testing
        ReenableRelationship   - Re-enables an Organization Relationship if XTAP testing fails
        RemoveRelationship     - Removes an Organization Relationship once XTAP is confirmed working
        DisableSharingPolicy   - Disables a Sharing Policy for side-by-side XTAP testing
        ReenableSharingPolicy  - Re-enables a Sharing Policy if XTAP testing fails
        RemoveSharingPolicy    - Removes a Sharing Policy once XTAP is confirmed working

.PARAMETER TenantId
    The external organization's Entra Tenant ID. Required for EstablishTrust.
    For GrantCapability, its presence signals partner-specific scope.

.PARAMETER RelationshipName
    The Organization Relationship name to act on. Required for
    DisableRelationship, ReenableRelationship, and RemoveRelationship.

.PARAMETER PolicyName
    The Sharing Policy name to act on. Required for DisableSharingPolicy,
    ReenableSharingPolicy, and RemoveSharingPolicy. Optional filter for
    CheckPolicyAssignment.

.PARAMETER DomainFilter
    A domain or name fragment (e.g. "contoso") used to match guest users by
    Mail or UserPrincipalName for the GuestReview phase.

.PARAMETER CapabilityType
    For GrantCapability: FreeBusy, MailTips, or CalendarSharing.

.PARAMETER Level
    For GrantCapability: the access level for the chosen CapabilityType.
        FreeBusy         -> AvailabilityOnly | LimitedDetails
        MailTips         -> Limited | All
        CalendarSharing  -> Simple | Detail | Reviewer

.PARAMETER Anonymous
    For GrantCapability with CapabilityType CalendarSharing: grants the
    anonymous calendar-publishing capability instead of a partner or
    org-wide one. Anonymous capabilities only exist on the default policy,
    per Microsoft's guide -- do not combine with -TenantId.

.PARAMETER GroupId
    Optional Entra security group ID to scope the granted capability to
    specific internal users instead of everyone. If provided, GrantCapability
    uses it directly without prompting (for scripted/non-interactive use). If
    omitted, GrantCapability prompts interactively to ask whether to scope to
    All users or a specific group -- scope is never silently defaulted.

.EXAMPLE
    .\Invoke-CrossTenantSharingMigration.ps1 -Phase Inventory

.EXAMPLE
    .\Invoke-CrossTenantSharingMigration.ps1 -Phase GuestReview -DomainFilter "contoso"

.EXAMPLE
    .\Invoke-CrossTenantSharingMigration.ps1 -Phase EstablishTrust -TenantId "<partnerTenantId>"

.EXAMPLE
    # Partner-specific Free/Busy (AvailabilityOnly)
    .\Invoke-CrossTenantSharingMigration.ps1 -Phase GrantCapability -TenantId "<partnerTenantId>" -CapabilityType FreeBusy -Level AvailabilityOnly

.EXAMPLE
    # Org-wide (default policy) wildcard Calendar Sharing, Simple detail level
    .\Invoke-CrossTenantSharingMigration.ps1 -Phase GrantCapability -CapabilityType CalendarSharing -Level Simple

.EXAMPLE
    # Anonymous calendar publishing, Simple detail level
    .\Invoke-CrossTenantSharingMigration.ps1 -Phase GrantCapability -CapabilityType CalendarSharing -Level Simple -Anonymous

.EXAMPLE
    .\Invoke-CrossTenantSharingMigration.ps1 -Phase DisableSharingPolicy -PolicyName "Default Sharing Policy" -WhatIf

.NOTES
    Author:   Josh Block (j0shbl0ck)
    Version:  2.1.0
    Repo:     https://github.com/j0shbl0ck
    Requires: ExchangeOnlineManagement module + active Connect-ExchangeOnline session
              Microsoft Graph PowerShell SDK Beta for EstablishTrust/GrantCapability
    Reminder: Get-OrganizationRelationship's FreeBusyAccessScope/MailTipsAccessScope
              aren't shown by the Inventory phase's default columns -- re-run
              Get-OrganizationRelationship directly with those properties if you
              need to confirm an existing relationship was already scoped to a
              group before choosing -GroupId here.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'Inventory',
        'CheckPolicyAssignment',
        'GuestReview',
        'EstablishTrust',
        'GrantCapability',
        'DisableRelationship',
        'ReenableRelationship',
        'RemoveRelationship',
        'DisableSharingPolicy',
        'ReenableSharingPolicy',
        'RemoveSharingPolicy'
    )]
    [string]$Phase,

    [string]$TenantId,

    [string]$RelationshipName,

    [string]$PolicyName,

    [string]$DomainFilter,

    [ValidateSet('FreeBusy', 'MailTips', 'CalendarSharing')]
    [string]$CapabilityType,

    [ValidateSet('AvailabilityOnly', 'LimitedDetails', 'Limited', 'All', 'Simple', 'Detail', 'Reviewer')]
    [string]$Level,

    [switch]$Anonymous,

    [string]$GroupId
)

#region Helper: connection checks
function Assert-ExchangeOnlineConnected {
    try { $null = Get-ConnectionInformation -ErrorAction Stop }
    catch {
        Write-Host "Not connected to Exchange Online. Connecting now..." -ForegroundColor Yellow
        Connect-ExchangeOnline -ShowBanner:$false
    }
}

function Assert-GraphConnected {
    try { $null = Get-MgContext -ErrorAction Stop }
    catch {
        Write-Host "Not connected to Microsoft Graph. Connecting now..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes "Policy.Read.All,Policy.ReadWrite.CrossTenantAccess,Policy.ReadWrite.CrossTenantCapability" -ContextScope Process
    }
}
#endregion

#region Helper: capability name lookup (Microsoft's Replaces table from the migration guide)
$CapabilityMap = @{
    'FreeBusy|AvailabilityOnly'    = 'crossTenantCalendarAvailabilityBasic'
    'FreeBusy|LimitedDetails'      = 'crossTenantCalendarAvailabilityLimitedDetails'
    'MailTips|Limited'             = 'crossTenantMailTipsLimited'
    'MailTips|All'                 = 'crossTenantMailTipsAll'
    'CalendarSharing|Simple'       = 'crossTenantCalendarSharingFreeBusySimple'
    'CalendarSharing|Detail'       = 'crossTenantCalendarSharingFreeBusyDetail'
    'CalendarSharing|Reviewer'     = 'crossTenantCalendarSharingFreeBusyReviewer'
}

$AnonymousCapabilityMap = @{
    'Simple'   = 'AnonymousCalendarFreeBusySimple'
    'Detail'   = 'AnonymousCalendarSharingFreeBusyDetail'
    'Reviewer' = 'AnonymousCalendarSharingFreeBusyReviewer'
}
#endregion

switch ($Phase) {

    #region Part 1 -- Inventory existing configurations
    'Inventory' {
        Assert-ExchangeOnlineConnected
        Write-Host "`n=== Organization Relationships ===" -ForegroundColor Cyan
        Get-OrganizationRelationship | Format-List Name, DomainNames, Enabled, `
            FreeBusyAccessEnabled, FreeBusyAccessLevel, FreeBusyAccessScope, `
            MailTipsAccessEnabled, MailTipsAccessLevel, MailTipsAccessScope, `
            TargetSharingEpr, TargetAutodiscoverEpr, TargetApplicationUri

        Write-Host "`n=== Sharing Policies ===" -ForegroundColor Cyan
        Get-SharingPolicy | Format-List Name, Enabled, Domains, Default

        Write-Host "`nCheck each Organization Relationship's Target*Epr/Uri values for outlook.com, office365.com, or office365.us to confirm the partner is hosted in Microsoft 365 before migrating." -ForegroundColor DarkGray
    }
    #endregion

    #region Check which mailboxes are assigned to which Sharing Policy
    'CheckPolicyAssignment' {
        Assert-ExchangeOnlineConnected
        Write-Host "`n=== Sharing Policy Assignment ===" -ForegroundColor Cyan

        $mailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox, SharedMailbox -Properties SharingPolicy

        $summary = $mailboxes | Group-Object SharingPolicy | Select-Object Name, Count
        $summary | Format-Table -AutoSize

        if ($PolicyName) {
            $matches = $mailboxes | Where-Object { $_.SharingPolicy -eq $PolicyName } |
                Select-Object DisplayName, PrimarySmtpAddress, SharingPolicy
            Write-Host "`nMailboxes assigned to '$PolicyName': $($matches.Count)" -ForegroundColor $(if ($matches.Count -gt 0) { "Yellow" } else { "Green" })
            $matches
        }
    }
    #endregion

    #region Guest sign-in review, to help assess whether a relationship is still in active use
    'GuestReview' {
        if (-not $DomainFilter) { throw "Provide -DomainFilter (e.g. a vendor's domain or name fragment)." }
        Assert-GraphConnected
        Write-Host "`n=== Guest User Sign-In Review: '$DomainFilter' ===" -ForegroundColor Cyan

        $guests = Get-MgUser -Filter "userType eq 'Guest'" -All |
            Where-Object { $_.Mail -like "*$DomainFilter*" -or $_.UserPrincipalName -like "*$DomainFilter*" }

        if (-not $guests) {
            Write-Host "No guest users matched '$DomainFilter'." -ForegroundColor Yellow
        }

        foreach ($guest in $guests) {
            $signIn = Get-MgAuditLogSignIn -Filter "userId eq '$($guest.Id)'" -Top 1 -Sort "createdDateTime desc" -ErrorAction SilentlyContinue
            $lastSignIn = if ($signIn) { $signIn.CreatedDateTime } else { "Never" }

            Write-Host "`n$($guest.DisplayName) ($($guest.UserPrincipalName))" -ForegroundColor White
            Write-Host "  Last Sign-In: $lastSignIn" -ForegroundColor $(if ($lastSignIn -eq "Never") { "DarkGray" } else { "Green" })
        }

        Write-Host "`nSign-in activity is one signal, not the whole picture -- confirm against active contracts/engagements before deciding to remove a relationship." -ForegroundColor DarkGray
    }
    #endregion

    #region Part 2 -- Establish Entra XTAP trust with a partner tenant
    'EstablishTrust' {
        if (-not $TenantId) { throw "Provide -TenantId for the partner organization." }
        Assert-GraphConnected

        $body = @{
            tenantId                 = $TenantId
            m365CollaborationInbound = @{
                users = @{
                    accessType = "allowed"
                    targets    = @(
                        @{ target = "AllUsers"; targetType = "user" }
                    )
                }
            }
        }

        if ($PSCmdlet.ShouldProcess($TenantId, "New-MgBetaPolicyCrossTenantAccessPolicyPartner")) {
            New-MgBetaPolicyCrossTenantAccessPolicyPartner -BodyParameter $body
            Write-Host "Established Microsoft 365 Collaboration trust with tenant $TenantId." -ForegroundColor Green
            Write-Host "This trust covers ALL domains verified in that tenant automatically -- there is no per-domain exclusion once granted." -ForegroundColor DarkGray
        }
    }
    #endregion

    #region Part 2 -- Grant a Free/Busy, MailTips, or Calendar Sharing capability
    'GrantCapability' {
        if (-not $CapabilityType) { throw "Provide -CapabilityType (FreeBusy, MailTips, or CalendarSharing)." }
        if (-not $Level) { throw "Provide -Level for the chosen -CapabilityType." }
        if ($Anonymous -and $TenantId) { throw "-Anonymous and -TenantId are mutually exclusive -- anonymous capabilities live on the default policy only." }
        if ($Anonymous -and $CapabilityType -ne 'CalendarSharing') { throw "-Anonymous only applies to -CapabilityType CalendarSharing." }

        Assert-GraphConnected

        $capability = if ($Anonymous) {
            if (-not $AnonymousCapabilityMap.ContainsKey($Level)) { throw "'$Level' has no anonymous equivalent. Valid values: $($AnonymousCapabilityMap.Keys -join ', ')" }
            $AnonymousCapabilityMap[$Level]
        }
        else {
            $key = "$CapabilityType|$Level"
            if (-not $CapabilityMap.ContainsKey($key)) { throw "'$Level' is not a valid Level for -CapabilityType $CapabilityType." }
            $CapabilityMap[$key]
        }

        # Determine scope: -GroupId provided skips the prompt (non-interactive/scripted use);
        # otherwise ask interactively so scope is always a deliberate choice, never a silent default.
        $resolvedGroupId = $GroupId

        if (-not $resolvedGroupId) {
            Write-Host ""
            Write-Host "  Scope this capability to:" -ForegroundColor Cyan
            Write-Host "    [1] All users in the organization"
            Write-Host "    [2] A specific security group (Object ID)"

            do {
                $scopeChoice = Read-Host "  Enter 1 or 2"
            } while ($scopeChoice -notin @('1', '2'))

            if ($scopeChoice -eq '2') {
                do {
                    $resolvedGroupId = Read-Host "  Enter the security group's Object ID (GUID)"
                    if ($resolvedGroupId -notmatch '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$') {
                        Write-Host "  That doesn't look like a valid GUID -- try again." -ForegroundColor Yellow
                        $resolvedGroupId = $null
                    }
                } while (-not $resolvedGroupId)
            }
        }

        $group = if ($resolvedGroupId) {
            @{ resourceId = $resolvedGroupId; resourceType = "group" }
        }
        else {
            @{ resourceId = "All"; resourceType = "user" }
        }

        $scopeSummary = if ($resolvedGroupId) { "group $resolvedGroupId" } else { "All users" }
        Write-Host "`n  Scope: $scopeSummary" -ForegroundColor DarkGray

        $body = @{
            "@odata.type" = "microsoft.graph.$capability"
            inboundAccess = @{
                isAllowed      = $true
                resourceScopes = @{
                    included = @($group)
                    excluded = @(@{})
                }
            }
        }

        if ($TenantId) {
            # Partner-specific scope
            if ($PSCmdlet.ShouldProcess($TenantId, "New-MgBetaPolicyCrossTenantAccessPolicyPartnerM365Capability ($capability)")) {
                New-MgBetaPolicyCrossTenantAccessPolicyPartnerM365Capability -CrossTenantAccessPolicyConfigurationPartnerTenantId $TenantId -BodyParameter $body
                Write-Host "Granted $capability to partner tenant $TenantId." -ForegroundColor Green
            }
        }
        else {
            # Default (org-wide / wildcard / anonymous) scope
            $scopeLabel = if ($Anonymous) { "Default Cross-Tenant Access Policy (Anonymous)" } else { "Default Cross-Tenant Access Policy (org-wide)" }
            if ($PSCmdlet.ShouldProcess($scopeLabel, "New-MgBetaPolicyCrossTenantAccessPolicyDefaultM365Capability ($capability)")) {
                New-MgBetaPolicyCrossTenantAccessPolicyDefaultM365Capability -BodyParameter $body
                Write-Host "Granted $capability via $scopeLabel." -ForegroundColor Green
            }
        }
    }
    #endregion

    #region Part 3 -- Disable an Organization Relationship for side-by-side testing
    'DisableRelationship' {
        if (-not $RelationshipName) { throw "Provide -RelationshipName." }
        Assert-ExchangeOnlineConnected
        if ($PSCmdlet.ShouldProcess($RelationshipName, "Set-OrganizationRelationship -Enabled `$False")) {
            Set-OrganizationRelationship -Identity $RelationshipName -Enabled $false
            Write-Host "Disabled '$RelationshipName'. Coordinate with the partner admin to test XTAP now." -ForegroundColor Yellow
        }
    }
    #endregion

    #region Part 3 -- Re-enable an Organization Relationship if testing fails
    'ReenableRelationship' {
        if (-not $RelationshipName) { throw "Provide -RelationshipName." }
        Assert-ExchangeOnlineConnected
        if ($PSCmdlet.ShouldProcess($RelationshipName, "Set-OrganizationRelationship -Enabled `$True")) {
            Set-OrganizationRelationship -Identity $RelationshipName -Enabled $true
            Write-Host "Re-enabled '$RelationshipName'." -ForegroundColor Yellow
        }
    }
    #endregion

    #region Part 4 -- Remove an Organization Relationship once XTAP is confirmed
    'RemoveRelationship' {
        if (-not $RelationshipName) { throw "Provide -RelationshipName." }
        Assert-ExchangeOnlineConnected
        if ($PSCmdlet.ShouldProcess($RelationshipName, "Remove-OrganizationRelationship")) {
            Remove-OrganizationRelationship -Identity $RelationshipName
            Write-Host "Removed '$RelationshipName'." -ForegroundColor Green
        }
    }
    #endregion

    #region Part 3 -- Disable a Sharing Policy for side-by-side testing
    'DisableSharingPolicy' {
        if (-not $PolicyName) { throw "Provide -PolicyName." }
        Assert-ExchangeOnlineConnected
        if ($PSCmdlet.ShouldProcess($PolicyName, "Set-SharingPolicy -Enabled `$False")) {
            Set-SharingPolicy -Identity $PolicyName -Enabled $false
            Write-Host "Disabled '$PolicyName'. Watch for reports of broken external calendar-sharing invitations." -ForegroundColor Yellow
        }
    }
    #endregion

    #region Part 3 -- Re-enable a Sharing Policy if testing fails
    'ReenableSharingPolicy' {
        if (-not $PolicyName) { throw "Provide -PolicyName." }
        Assert-ExchangeOnlineConnected
        if ($PSCmdlet.ShouldProcess($PolicyName, "Set-SharingPolicy -Enabled `$True")) {
            Set-SharingPolicy -Identity $PolicyName -Enabled $true
            Write-Host "Re-enabled '$PolicyName'." -ForegroundColor Yellow
        }
    }
    #endregion

    #region Part 4 -- Remove a Sharing Policy once XTAP is confirmed
    'RemoveSharingPolicy' {
        if (-not $PolicyName) { throw "Provide -PolicyName." }
        Assert-ExchangeOnlineConnected
        if ($PSCmdlet.ShouldProcess($PolicyName, "Remove-SharingPolicy")) {
            Remove-SharingPolicy -Identity $PolicyName
            Write-Host "Removed '$PolicyName'." -ForegroundColor Green
        }
    }
    #endregion
}
