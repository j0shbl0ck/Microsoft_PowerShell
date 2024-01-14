<#
.SYNOPSIS
    This enables and brands the O365 Message Encryption feature from Microsoft.
.NOTES
    Author: Josh Block
    Date: 08.20.22
    Type: Public
    Version: 1.0.1
.LINK
    https://github.com/j0shbl0ck
    https://docs.microsoft.com/en-us/azure/information-protection/activate-service#how-to-activate-or-confirm-the-status-of-the-protection-service
    https://docs.microsoft.com/en-us/microsoft-365/compliance/add-your-organization-brand-to-encrypted-messages?view=o365-worldwide
#>

Clear-Host

# Connect to Azure Information Protection Service
Connect-AipService | Clear-Host

# Connect to Exchange Online
Connect-ExchangeOnline | Clear-Host

# Activate Rights Management protection service
Enable-AipService

# Customize O365 Message Encryption branding
Set-OMEConfiguration -Identity "OME Configuration" -Confirm:$false -BackgroundColor "#01345e" 

Set-OMEConfiguration -Identity "OME Configuration" -Confirm:$false -DisclaimerText "This message is confidential for the use of this addressee only."

Set-OMEConfiguration -Identity "OME Configuration" -Confirm:$false -EmailText "Encrypted messages sent by organization are secured by, Microsoft Purview Message Encryption" 

Set-OMEConfiguration -Identity "OME Configuration" -Confirm:$false -Image ([System.IO.File]::ReadAllBytes("C:\Users\JohnDoe\Untitled.png"))

Set-OMEConfiguration -Identity "OME Configuration" -Confirm:$false -IntroductionText "has sent you a secure email."

Set-OMEConfiguration -Identity "OME Configuration" -Confirm:$false -ReadButtonText "View this message"

Set-OMEConfiguration -Identity "OME Configuration" -Confirm:$false -PortalText "<Organization> Message Portal"
