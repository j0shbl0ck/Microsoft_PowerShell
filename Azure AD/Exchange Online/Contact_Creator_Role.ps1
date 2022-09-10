<#
.SYNOPSIS
    This creates a new role in in Exchange Admin to assign to a role group. 
.NOTES
    Author: Josh Block
    Date: 09.09.22
    Type: Public
    Version: 1.0.0
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
# ask for the name of the role
$roleName = Read-Host -Prompt "Enter the name of the contact creator role: "
Write-Host -ForegroundColor Yellow 'Creating a new role...'
New-ManagementRole -Name $roleName -Description "Allows full control for creation and deletion of contacts within the Global Address List." -Parent "Mail Recipient Creation"
Write-Host -ForegroundColor Green "$roleName created successfully!`n"

# Assign proper management roles to the new role.
Write-Host -ForegroundColor Yellow 'Assigning management roles to the Contact Admin...'
Get-ManagementRoleEntry "$roleName\*" | Where-Object {$_.Name -notlike "*MailContact"} | Remove-ManagementRoleEntry
Write-Host -ForegroundColor Green "Management roles assigned successfully!`n"

# Show the new role.
Write-Host -ForegroundColor Magenta 'Presenting new role...'
Get-ManagementRoleEntry "$roleName\*" | Format-List Name
Pause


