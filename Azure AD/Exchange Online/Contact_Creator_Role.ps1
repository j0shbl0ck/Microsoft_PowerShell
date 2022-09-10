<#
.SYNOPSIS
    This creates a new Contact Admin role in Exchange Admin to assign to a role group. 
.NOTES
    Author: Josh Block
    Date: 09.09.22
    Type: Public
    Version: 1.0.2
.LINK
    https://github.com/j0shbl0ck
    https://practical365.com/exchange-server-role-based-access-control-in-action/#:~:text=The%20easiest%20way%20to%20create%20a%20custom%20role,Next%2C%20click%20the%20icon%20to%20add%20a%20role.
    https://4sysops.com/archives/create-custom-rbac-roles-in-exchange-and-office-365/
#>

Clear-Host

# Connect to Exchange Online via Azure AD with Global/Exchange admin.
Write-Host -ForegroundColor Cyan 'Connecting to Exchange Online...'
Connect-ExchangeOnline
Clear-Host

## Create a new role.
Write-Host -ForegroundColor Yellow 'Creating a new role...'
New-ManagementRole -Name "Contact Admin" -Description "Allows full control for creation and deletion of contacts within the Global Address List." -Parent "Mail Recipient Creation"
Write-Host -ForegroundColor Green "Contact Admin created successfully!`n"

# Assign proper management roles to the new role.
Write-Host -ForegroundColor Yellow "Re-assigning management roles to $roleName..."
Get-ManagementRoleEntry "Contact Admin\*" | Where-Object {$_.Name -notlike '*MailContact'} | ForEach-Object {Remove-ManagementRoleEntry -Identity "$($_.id)\$($_.name)" -Confirm:$False} 
Write-Host -ForegroundColor Green "Management roles assigned successfully!`n"

# Show the new role.
Write-Host -ForegroundColor Magenta 'Presenting new management roles...'
Get-ManagementRoleEntry "Contact Admin\*" | Format-List Name
Pause