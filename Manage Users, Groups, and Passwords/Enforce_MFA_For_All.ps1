<#
.SYNOPSIS
    This script enforces MFA for all users within the tenant
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 03.29.22
    Type: Public
.NOTES

.LINK
    https://www.c-sharpcorner.com/blogs/how-to-enable-and-disable-mfa-using-powershell
#>

# Connect MSOnline
$cred = New-Object System.Management.Automation.PSCredential("infinitech@basilmcrae.com", "wmGmEWqx3JpQpX_rJdXLQB8Cm6sw1XYS")
Connect-MsolService 

# Make status to "Enforced"
$st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$st.RelyingParty = "*"
$st.State = "Enforced" 
$sta = @($st)
Set-MsolUser -UserPrincipalName $upn -StrongAuthenticationRequirements $sta -StrongAuthenticationMethods $sm
Get-MsolUser –All | Foreach{ Set-MsolUser -UserPrincipalName $_.UserPrincipalName -StrongAuthenticationRequirements $sta}
# this script works above 

# Connect MSOnline


$UserName=Read-Host"Enter the username"  
$authentication=New-Object -TypeNameMicrosoft.Online.Administration.StrongAuthenticationRequirement  
$authentication.RelyingParty ="*"  
$authentication.State ="Enforced"  
Get-MsolUser –All | Foreach{ Set-MsolUser -UserPrincipalName $_.UserPrincipalName -StrongAuthenticationRequirements $authentication}


Connect-MSolservice
$upn = "0119@zzjtest.onmicrosoft.com"       #(Target user, if you have csv file of target users, you may re-write the script to go through the UPNs from csv file)
$st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$st.RelyingParty = "*"
$st.State = "Enforced" 
$sta = @($st)
Set-MsolUser -UserPrincipalName $upn -StrongAuthenticationRequirements $sta -StrongAuthenticationMethods $sm
Get-MsolUser –All | Foreach{ Set-MsolUser -UserPrincipalName $_.UserPrincipalName -StrongAuthenticationRequirements $sta}