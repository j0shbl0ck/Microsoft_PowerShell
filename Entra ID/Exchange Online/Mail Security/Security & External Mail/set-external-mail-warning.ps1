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
    https://www.architechlabs.io/articles/external-email-banner/
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
<table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="
  width:100%;
  background-color:#c62828;
  border:1px solid #8e0000;
  margin-bottom:10px;
">
  <tr>
    <td style="
      padding:10px 12px;
      font-family:Calibri, Arial, sans-serif;
      font-size:11pt;
      line-height:1.4;
      color:#ffffff;
    ">
      <span style="
        color:#ffff66;
        font-weight:bold;
      ">
        WARNING:
      </span>
      This message has <strong>originated from outside the organization</strong>.
      Please use proper judgment and caution when opening attachments, clicking links, or responding to this email.
    </td>
  </tr>
</table>
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
