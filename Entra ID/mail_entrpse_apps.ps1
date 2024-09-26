<#
.SYNOPSIS
    This script is made for prompting and accepting Enterprise Application: Apple Internet Accounts & Samsung Email
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 09.26.24
    Type: Public
.EXAMPLE
    
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
    You will need to have Microsoft Graph module [ Install-Module -Name Microsoft.Graph]
#>

Clear-Host
# Apple Email
Start-Process "https://login.microsoftonline.com/organizations/v2.0/adminconsent?client_id=f8d98a96-0999-43f5-8af3-69971c7bb423&redirect_uri=https%3A%2F%2Fadmin.microsoft.com%2FAdminportal%2FHome&scope=.default"

# Samsung Email
Start-Process "https://login.microsoftonline.com/organizations/v2.0/adminconsent?client_id=8acd33ea-7197-4a96-bc33-d7cc7101262f&redirect_uri=https%3A%2F%2Fadmin.microsoft.com%2FAdminportal%2FHome&scope=.default"