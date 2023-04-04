<#
.SYNOPSIS
    This script imports users from a CSV file and creates them in Active Directory.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 04.04.23
    Type: Public
.NOTES
    You will need to have Active Directory PowerShell module [ Import-Module ActiveDirectory ]
.LINK
    
#>

Clear-Host

# Import the AD module
Import-Module activedirectory
  
# Store the data from NewADUsers.csv in the $ADUsers variable
$ADUsers = Import-csv C:\temp\NewADUsers.csv

# Loop through each row in the CSV Sheet 
foreach ($User in $ADUsers)
{
	# Read data from each field in the row and assign data to a variable
	$Username  	= $User.username
	$Password 	= $User.password
	$Firstname 	= $User.firstname
	$Lastname 	= $User.lastname
	$OU 		= $User.ou
    $email      = $User.email
    $company    = $User.company
    $Password   = $User.Password
    # proxy address includes the email address with SMTP: in front of it
    $proxyaddress = "SMTP:$email"

	# Check if user already exists
	if (Get-ADUser -F {SamAccountName -eq $Username})
	{
		 # If user exists, give warning
		 Write-Warning "User account $Username already exists."
	}
	else
	{
		# User does not exist so proceed with creation of new user account
		
		New-ADUser `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@domain.com" `
            -Name "$Firstname $Lastname" `
            -GivenName $Firstname `
            -Surname $Lastname `
            -Enabled $True `
            -DisplayName "$Firstname $Lastname" `
            -Path $OU `
            -Company $company `
            -EmailAddress $email `
            -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $True 
        Set-aduser -Identity $Username -add @{proxyaddresses = "$proxyaddress"}
	}
}
