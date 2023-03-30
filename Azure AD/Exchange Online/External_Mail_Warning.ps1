<#
.SYNOPSIS
    This script auto creates a warning message for external messages.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.4
    Date: 03.30.23
    Type: Public
.EXAMPLE
    
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
#>

Clear-Host

# Ask user for Global/Exchange Admin UPN
$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)' 

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName $gadmin | Clear-Host

# Define the parameters
$Name = "External Email Disclaimer"
$Priority = 0
$Enabled = $true
$FromScope = "NotInOrganization"
$SentToScope = "InOrganization"
$ApplyHtmlDisclaimerText = '<div style="background-color: rgb(51, 56, 0) !important; width: 100%; border-style: solid; border-color: rgb(90, 67, 0); border-width: 1pt; padding: 2pt; font-size: 10pt; line-height: 12pt; font-family: Calibri; color: rgb(255, 255, 255) !important; text-align: left; margin-bottom: 2pt;" data-ogsc="black" data-ogsb="rgb(255, 199, 206)"><span style="color: rgb(255, 212, 0) !important; font-weight: bold;" data-ogsc="rgb(90, 67, 0)">WARNING:</span> This message has originated from outside the organization. Please use proper judgment and caution when opening attachments, clicking links, or responding to this email.</div>'
$ApplyHtmlDisclaimerLocation = "Prepend"
$ApplyHtmlDisclaimerFallbackAction = "Wrap"

# Create the transport rule
New-TransportRule -Name $Name -Priority $Priority -Enabled $Enabled -FromScope $FromScope -SentToScope $SentToScope -ApplyHtmlDisclaimerText $ApplyHtmlDisclaimerText -ApplyHtmlDisclaimerLocation $ApplyHtmlDisclaimerLocation -ApplyHtmlDisclaimerFallbackAction $ApplyHtmlDisclaimerFallbackAction

