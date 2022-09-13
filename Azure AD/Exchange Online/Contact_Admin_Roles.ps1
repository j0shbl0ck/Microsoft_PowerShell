<#
.SYNOPSIS
    This creates two custom Contact roles in Exchange Admin to assign to a role group. 
.NOTES
    Author: Josh Block
    Date: 09.09.22
    Type: Public
    Version: 1.0.4
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

Write-Host -ForegroundColor White "This script creates two custom roles, Contact Creator and Contact Modifer.`n These roles will need to be assigned to a role group such as Help Desk or a custom role group.`n"

## Create custom RBAC role - Contact Creator.
Write-Host -ForegroundColor Yellow 'Creating Contact Creator role...'
New-ManagementRole -Name "Contact Creator" -Description "Allows full control for creation and deletion of contacts within the Global Address List. Does not provide modification priviledges" -Parent "Mail Recipient Creation"
Write-Host -ForegroundColor Green "Contact Creator role created successfully!`n"

# Assign proper management roles to the Contact Creator role.
Write-Host -ForegroundColor Yellow "Re-assigning management roles to Contact Creator..."
Get-ManagementRoleEntry "Contact Creator\*" | Where-Object {$_.Name -notlike '*MailContact'} | ForEach-Object {Remove-ManagementRoleEntry -Identity "$($_.id)\$($_.name)" -Confirm:$False} 
Write-Host -ForegroundColor Green "Management roles assigned successfully!`n"

## Create custom RBAC role - Contact Modifier.
Write-Host -ForegroundColor Yellow 'Creating Contact Modifier role...'
New-ManagementRole -Name "Contact Modifier" -Description "Allows full control for modification to already existent contacts within the Global Address List. Does not provide creation/deletion priviledges" -Parent "Mail Recipients"
Write-Host -ForegroundColor Green "Contact Modifier created successfully!`n"

# Assign proper management roles to the Contact Modifier role.
Write-Host -ForegroundColor Yellow "Re-assigning management roles to Contact Modifier..."
Get-ManagementRoleEntry "Contact Modifier\*" | Where-Object {$_.Name -notlike '*MailContact'} | ForEach-Object {Remove-ManagementRoleEntry -Identity "$($_.id)\$($_.name)" -Confirm:$False} 
Add-ManagementRoleEntry  -Identity "Contact Modifier\Set-Contact"
Add-ManagementRoleEntry  -Identity "Contact Modifier\Get-Contact"
Add-ManagementRoleEntry  -Identity "Contact Modifier\Get-Recipient"

Write-Host -ForegroundColor Green "Management roles assigned successfully!`n"

# Show the new roles.
Write-Host -ForegroundColor Magenta 'Presenting new management roles...'
Get-ManagementRoleEntry "Contact Creator\*" | Format-List Name
Get-ManagementRoleEntry "Contact Modifier\*" | Format-List Name
Pause