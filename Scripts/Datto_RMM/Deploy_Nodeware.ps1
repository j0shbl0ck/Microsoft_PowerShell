<#
.SYNOPSIS
    This script deploys the Nodeware.
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 04.22.25
    Type: Public
.NOTES
    This script it built for the Datto RMM platform.
    Make sure you have all files uploaded to the component before deploying the script.
.LINK
    https://github.com/j0shbl0ck
#>

#Create Cisco Source directory and copy source installers
Remove-Item C:\Nodeware -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path C:\ -Name "Nodeware" -ItemType "Directory" -Force -ErrorAction SilentlyContinue

#Nodeware Source
Copy-Item .\NodewareAgentSetup.8631745.msi C:\Nodeware -Force
Start-Process Msiexec -Wait -ArgumentList '/package C:\Nodeware\NodewareAgentSetup.8631745.msi /qn'