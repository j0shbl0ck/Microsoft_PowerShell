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

# Get OID

Connect-ExchangeOnline -ShowBanner:$false

$oid = 'XXXXXX-1969-497d-9f6d-XXXXXXXXXX'
(Get-DistributionGroup -Identity $oid -ErrorAction Stop).DisplayName


(Get-PlacesSettings -ReadFromPrimary | Where-Object Name -eq 'Places.PlacesFinderEnabled').ScopedValues |
>>   ForEach-Object {
>>     $s = ($_ -is [pscustomobject] -and $_.Scope) ? $_.Scope : $_
>>     if ($s -match 'OID:([0-9a-fA-F-]+)@') { $matches[1] }
>>   } | Sort-Object -Unique



Connect-ExchangeOnline -ShowBanner:$false

Get-DistributionGroup 'Places Finder Users [XXXXXXX-6BB8-4441-XXXXXX-XXXXXXXXX]' | Select-Object -Property ExternalDirectoryObjectId
> OID: XXXXXXXX-630c-4ff2-XXXXX-XXXXXXXXX
> Places.PlacesFinderEnabled
> This parameter controls whether users can access Places finder and book individual desks

Get-DistributionGroup 'Places Analytics Users [XXXXXXX-6BB8-4441-XXXXXX-XXXXXXXXX]' | Select-Object -Property ExternalDirectoryObjectId
> OID: XXXXXXXX-630c-4ff2-XXXXX-XXXXXXXXX
> Places.SpaceAnalyticsEnabled
> This parameter controls whether users have access to Analytics.

Get-DistributionGroup 'Places Users [XXXXXXX-6BB8-4441-XXXXXX-XXXXXXXXX]' | Select-Object -Property ExternalDirectoryObjectId
> OID: XXXXXXXX-630c-4ff2-XXXXX-XXXXXXXXX
> Places.EnablePlacesWebApp
> This parameter controls whether users can access the Places app, on the web or inside Outlook, Teams and in Microsoft 365 app.