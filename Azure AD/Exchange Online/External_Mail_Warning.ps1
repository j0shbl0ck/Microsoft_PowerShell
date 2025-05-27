<#
.SYNOPSIS
    This script auto-creates a warning message for external messages.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.5
    Date: 03.30.23
    Type: Public
.EXAMPLE

.NOTES
    You will need to have the AzureAD PowerShell module:
        Install-Module -Name AzureAD

    You will need to have the Exchange Online module:
        Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5
#>

Clear-Host

# Ask user for Global/Exchange Admin UPN
$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)' 

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName $gadmin | Clear-Host

# Define the parameters
$Name                             = "External Email Disclaimer"
$Priority                         = 0
$Enabled                          = $true
$FromScope                        = "NotInOrganization"
$SentToScope                      = "InOrganization"
$ApplyHtmlDisclaimerText         = @'
<div style="
  width: 100%;
  padding: 6px 12px;
  font-size: 10pt;
  line-height: 1.3;
  font-family: Calibri, sans-serif;
  color: #ffffff;
  background: linear-gradient(to left, #ff4e50, #f00000);
  text-align: left;
  margin-bottom: 10px;
  border-radius: 6px;
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow: 0 0 10px rgba(255, 0, 0, 0.4);
">
  <span style="color: #ffff66; font-weight: bold;">⚠️ WARNING:</span>
  This message has <strong>originated from outside the organization</strong>.
  Please use proper judgment and caution when opening attachments, clicking links, or responding to this email.
</div>
'@
$ApplyHtmlDisclaimerLocation     = "Prepend"
$ApplyHtmlDisclaimerFallbackAction = "Wrap"

# Create the transport rule
New-TransportRule `
    -Name $Name `
    -Priority $Priority `
    -Enabled $Enabled `
    -FromScope $FromScope `
    -SentToScope $SentToScope `
    -ApplyHtmlDisclaimerText $ApplyHtmlDisclaimerText `
    -ApplyHtmlDisclaimerLocation $ApplyHtmlDisclaimerLocation `
    -ApplyHtmlDisclaimerFallbackAction $ApplyHtmlDisclaimerFallbackAction
