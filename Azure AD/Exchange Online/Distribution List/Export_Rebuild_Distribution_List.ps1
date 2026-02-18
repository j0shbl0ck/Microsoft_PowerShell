<#
.SYNOPSIS
    Exports a distribution list configuration and generates a rebuild script for Exchange Online.
.DESCRIPTION
    Captures detailed distribution list settings (name, SMTP/proxy addresses, owners, members,
    delivery restrictions, moderation settings, visibility settings, and join/depart behavior),
    writes a CSV snapshot, and creates a standalone restore script that can recreate the group.

    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.2.0
    Date: 02.18.26
    Type: Public
.NOTES
    Requires Exchange Online module:
      Install-Module -Name ExchangeOnlineManagement
#>

Clear-Host

function Convert-ToArrayLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Values
    )

    $filteredValues = @($Values | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($filteredValues.Count -eq 0) {
        return '@()'
    }

    $escapedValues = $filteredValues | ForEach-Object { $_.Replace("'", "''") }
    return "@('" + ($escapedValues -join "','") + "')"
}

function Convert-ToCsvValue {
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Values
    )

    if (-not $Values) {
        return ''
    }

    return (($Values | ForEach-Object { $_.ToString() }) -join ',')
}

function Resolve-RecipientNames {
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Identities
    )

    if (-not $Identities) {
        return @()
    }

    $resolved = @()
    foreach ($identity in $Identities) {
        if ($null -eq $identity) {
            continue
        }

        $idString = $identity.ToString()
        $recipient = Get-Recipient -Identity $idString -ErrorAction SilentlyContinue
        if ($recipient) {
            $resolved += $recipient.Name
        }
        else {
            $resolved += $idString
        }
    }

    return @($resolved)
}

$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)'
Connect-ExchangeOnline -UserPrincipalName $gadmin -ShowBanner:$false | Out-Null

$groupIdentity = Read-Host -Prompt 'Enter the distribution list email address or alias to export'
$outputFolder = Read-Host -Prompt 'Enter export folder path (Press Enter to use Desktop)'

if ([string]::IsNullOrWhiteSpace($outputFolder)) {
    $outputFolder = Join-Path $env:USERPROFILE 'Desktop'
}

if (-not (Test-Path -Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
}

$group = Get-DistributionGroup -Identity $groupIdentity -ErrorAction Stop
$members = @(Get-DistributionGroupMember -Identity $group.Identity -ResultSize Unlimited)
$membersPrimarySmtp = @($members | ForEach-Object { $_.PrimarySmtpAddress.ToString() })

$proxyAddresses = @($group.EmailAddresses | ForEach-Object { $_.ToString() })

$managedByIdentities = @($group.ManagedBy | ForEach-Object { $_.ToString() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$managedByNames = Resolve-RecipientNames -Identities $group.ManagedBy
$acceptMessagesOnlyFromNames = Resolve-RecipientNames -Identities $group.AcceptMessagesOnlyFrom
$grantSendOnBehalfToNames = Resolve-RecipientNames -Identities $group.GrantSendOnBehalfTo
$acceptMessagesOnlyFromDLMembersNames = Resolve-RecipientNames -Identities $group.AcceptMessagesOnlyFromDLMembers
$acceptMessagesOnlyFromSendersOrMembersNames = Resolve-RecipientNames -Identities $group.AcceptMessagesOnlyFromSendersOrMembers
$moderatedByNames = Resolve-RecipientNames -Identities $group.ModeratedBy
$bypassModerationNames = Resolve-RecipientNames -Identities $group.BypassModerationFromSendersOrMembers

$allowExternalSenders = -not $group.RequireSenderAuthenticationEnabled
$joinRestriction = if ([string]::IsNullOrWhiteSpace($group.MemberJoinRestriction)) { 'Closed' } else { $group.MemberJoinRestriction }
$memberDepartRestriction = if ([string]::IsNullOrWhiteSpace($group.MemberDepartRestriction)) { 'Closed' } else { $group.MemberDepartRestriction }
$notes = (Get-Group -Identity $group.Identity -ErrorAction SilentlyContinue).Notes

$exportObject = [PSCustomObject]@{
    DisplayName                            = $group.DisplayName
    Name                                   = $group.Name
    PrimarySmtpAddress                     = $group.PrimarySmtpAddress.ToString()
    EmailAddresses                         = Convert-ToCsvValue -Values $group.EmailAddresses
    Domain                                 = $group.PrimarySmtpAddress.ToString().Split('@')[1]
    Alias                                  = $group.Alias
    GroupType                              = $group.GroupType
    RecipientTypeDetails                   = $group.RecipientTypeDetails
    MembersPrimarySmtpAddress              = (Convert-ToCsvValue -Values $membersPrimarySmtp)
    ManagedBy                              = (Convert-ToCsvValue -Values $managedByNames)
    HiddenFromAddressLists                 = $group.HiddenFromAddressListsEnabled
    MemberJoinRestriction                  = $joinRestriction
    MemberDepartRestriction                = $memberDepartRestriction
    RequireSenderAuthenticationEnabled     = $group.RequireSenderAuthenticationEnabled
    AllowExternalSenders                   = $allowExternalSenders
    AcceptMessagesOnlyFrom                 = (Convert-ToCsvValue -Values $acceptMessagesOnlyFromNames)
    AcceptMessagesOnlyFromDLMembers        = (Convert-ToCsvValue -Values $acceptMessagesOnlyFromDLMembersNames)
    AcceptMessagesOnlyFromSendersOrMembers = (Convert-ToCsvValue -Values $acceptMessagesOnlyFromSendersOrMembersNames)
    ModeratedBy                            = (Convert-ToCsvValue -Values $moderatedByNames)
    BypassModerationFromSendersOrMembers   = (Convert-ToCsvValue -Values $bypassModerationNames)
    ModerationEnabled                      = $group.ModerationEnabled
    SendModerationNotifications            = $group.SendModerationNotifications
    GrantSendOnBehalfTo                    = (Convert-ToCsvValue -Values $grantSendOnBehalfToNames)
    Notes                                  = $notes
}

$safeName = ($group.DisplayName -replace '[^A-Za-z0-9._-]', '_')
$csvPath = Join-Path $outputFolder "$safeName-DistributionGroupSnapshot.csv"
$rebuildScriptPath = Join-Path $outputFolder "$safeName-RebuildDistributionGroup.ps1"

$exportObject | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$ownersArrayLiteral = Convert-ToArrayLiteral -Values $managedByIdentities
$membersArrayLiteral = Convert-ToArrayLiteral -Values $membersPrimarySmtp
$proxyAddressesArrayLiteral = Convert-ToArrayLiteral -Values $proxyAddresses
$boolLiteral = if ($allowExternalSenders) { '$true' } else { '$false' }
$hiddenLiteral = if ($group.HiddenFromAddressListsEnabled) { '$true' } else { '$false' }
$moderationLiteral = if ($group.ModerationEnabled) { '$true' } else { '$false' }

$rebuildScript = @"
# Auto-generated from $($group.PrimarySmtpAddress)
# Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

param(
    [Parameter(Mandatory=`$false)]
    [string]`$AdminUPN
)

if (-not `$AdminUPN) {
    `$AdminUPN = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)'
}

Connect-ExchangeOnline -UserPrincipalName `$AdminUPN -ShowBanner:`$false | Out-Null

`$name = '$($group.DisplayName -replace "'", "''")'
`$primarySmtpAddress = '$($group.PrimarySmtpAddress.ToString())'
`$alias = '$($group.Alias -replace "'", "''")'
`$owners = $ownersArrayLiteral
`$members = $membersArrayLiteral
`$proxyAddresses = $proxyAddressesArrayLiteral
`$allowExternalSenders = $boolLiteral
`$joinRestriction = '$joinRestriction'
`$memberDepartRestriction = '$memberDepartRestriction'
`$hiddenFromAddressLists = $hiddenLiteral
`$moderationEnabled = $moderationLiteral
`$sendModerationNotifications = '$($group.SendModerationNotifications)'

if ([string]::IsNullOrWhiteSpace(`$joinRestriction)) {
    `$joinRestriction = 'Closed'
}

if ([string]::IsNullOrWhiteSpace(`$memberDepartRestriction)) {
    `$memberDepartRestriction = 'Closed'
}

# IMPORTANT: Ensure owners are resolvable mail-enabled recipients (users or a Mail-Enabled Security Group).
# Example: 'dl-owners@contoso.com' or specific user UPNs.

# Create if not exists
`$existingGroup = Get-DistributionGroup -Identity `$primarySmtpAddress -ErrorAction SilentlyContinue
if (-not `$existingGroup) {
    New-DistributionGroup -Name `$name -PrimarySmtpAddress `$primarySmtpAddress -Alias `$alias -Type Distribution | Out-Null
}

# Use splatting to avoid line continuation issues
`$setDG = @{
    Identity                           = `$primarySmtpAddress
    MemberJoinRestriction              = `$joinRestriction
    MemberDepartRestriction            = `$memberDepartRestriction
    RequireSenderAuthenticationEnabled = (-not `$allowExternalSenders)
    HiddenFromAddressListsEnabled      = `$hiddenFromAddressLists
    ModerationEnabled                  = `$moderationEnabled
    SendModerationNotifications        = `$sendModerationNotifications
}
Set-DistributionGroup @setDG | Out-Null

if (`$proxyAddresses.Count -gt 0) {
    # Replaces all proxy addresses; ensure the list is authoritative.
    Set-DistributionGroup -Identity `$primarySmtpAddress -EmailAddresses `$proxyAddresses | Out-Null
}

if (`$owners.Count -gt 0) {
    try {
        Set-DistributionGroup -Identity `$primarySmtpAddress -ManagedBy `$owners -BypassSecurityGroupManagerCheck -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Warning "Failed to set owners (`$(`$owners -join ', ')). Ensure each is a mail-enabled recipient (e.g., user or Mail-Enabled Security Group). Error: `$(`$_.Exception.Message)"
    }
}

foreach (`$member in `$members) {
    if (-not [string]::IsNullOrWhiteSpace(`$member)) {
        Add-DistributionGroupMember -Identity `$primarySmtpAddress -Member `$member -BypassSecurityGroupManagerCheck -ErrorAction SilentlyContinue
    }
}

Write-Host "Distribution list rebuild complete for `$primarySmtpAddress" -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:`$false
"@

Set-Content -Path $rebuildScriptPath -Value $rebuildScript -Encoding UTF8

Write-Host "`nExport complete:" -ForegroundColor Green
Write-Host "Snapshot CSV : $csvPath" -ForegroundColor Cyan
Write-Host "Rebuild script: $rebuildScriptPath" -ForegroundColor Cyan

Disconnect-ExchangeOnline -Confirm:$false
