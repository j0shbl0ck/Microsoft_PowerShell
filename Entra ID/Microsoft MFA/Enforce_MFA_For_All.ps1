<#
.SYNOPSIS
    This script enforces MFA for all users within the tenant
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.3
    Date: 03.29.22
    Type: Public
.NOTES
    Ensure you make note of your global/service accounts that you will want to disable MFA after the script runs.
.LINK
    https://www.c-sharpcorner.com/blogs/how-to-enable-and-disable-mfa-using-powershell
#>

# Connect MSOnline
Connect-MsolService 

# Make status to "Enforced"
Try {
    $st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $st.RelyingParty = "*"
    $st.State = "Enabled" 
    $sta = @($st)
    Get-MsolUser -All | ForEach-Object{ Set-MsolUser -UserPrincipalName $_.UserPrincipalName -StrongAuthenticationRequirements $sta}
    Write-Host -ForegroundColor Green "Strong authentication requirements set successfully for all users."
}
Catch {
    Write-Host -ForegroundColor Red "An error occurred: $_"
}

