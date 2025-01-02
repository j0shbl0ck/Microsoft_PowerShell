<#
.SYNOPSIS
    This script deploys the Cisco Secure Client to a Windows device.
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 01.02.24
    Type: Public
.NOTES
    This script it built for the Datto RMM platform.
    Make sure you have all files uploaded to the component before deploying the script.
.LINK
    https://github.com/j0shbl0ck
#>

#Create Cisco Source directory and copy source installers
Remove-Item C:\CiscoSource -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path C:\ -Name "CiscoSource" -ItemType "Directory" -Force -ErrorAction SilentlyContinue

#VPN Module
Copy-Item .\cisco-secure-client-win-5.1.6.103-core-vpn-predeploy-k9.msi C:\CiscoSource -Force
Start-Process Msiexec -Wait -ArgumentList '/package C:\CiscoSource\cisco-secure-client-win-5.1.6.103-core-vpn-predeploy-k9.msi /norestart /passive /qn /lvx* C:\CiscoSource\cisco-secure-client-win-5.1.6.103-core-vpn-predeploy-k9.log'
Copy-Item .\AnyConnectProfile.xml "$env:ProgramData\Cisco\Cisco Secure Client\VPN\Profile\" -Force

#ISE Posture
Copy-Item .\cisco-secure-client-win-5.1.6.103-iseposture-predeploy-k9.msi C:\CiscoSource -Force
Start-Process Msiexec -Wait -ArgumentList '/package C:\CiscoSource\cisco-secure-client-win-5.1.6.103-iseposture-predeploy-k9.msi /norestart /passive /qn /lvx* C:\CiscoSource\cisco-secure-client-win-5.1.6.103-iseposture-predeploy-k9.log'
Copy-Item .\ISEPostureCFG.xml "$env:ProgramData\Cisco\Cisco Secure Client\ISE Posture\" -Force

#Network Access Manager
Copy-Item .\cisco-secure-client-win-5.1.6.103-nam-predeploy-k9.msi C:\CiscoSource -Force
Start-Process Msiexec -Wait -ArgumentList '/package C:\CiscoSource\cisco-secure-client-win-5.1.6.103-nam-predeploy-k9.msi /norestart /passive /qn /lvx* C:\CiscoSource\cisco-secure-client-win-5.1.6.103-nam-predeploy-k9.log'
Copy-Item .\configuration.xml "$env:ProgramData\Cisco\Cisco Secure Client\Network Access Manager\system\" -Force

#Network Visibility
Copy-Item .\cisco-secure-client-win-5.1.6.103-nvm-predeploy-k9.msi C:\CiscoSource -Force
Start-Process Msiexec -Wait -ArgumentList '/package C:\CiscoSource\cisco-secure-client-win-5.1.6.103-nvm-predeploy-k9.msi /norestart /passive /qn /lvx* C:\CiscoSource\cisco-secure-client-win-5.1.6.103-nvm-predeploy-k9.log'

#DART
Copy-Item .\cisco-secure-client-win-5.1.6.103-dart-predeploy-k9.msi C:\CiscoSource -Force
Start-Process Msiexec -Wait -ArgumentList '/package C:\CiscoSource\cisco-secure-client-win-5.1.6.103-dart-predeploy-k9.msi /norestart /passive /qn /lvx* C:\CiscoSource\cisco-secure-client-win-5.1.6.103-dart-predeploy-k9.log'

#SBL
Copy-Item .\cisco-secure-client-win-5.1.6.103-sbl-predeploy-k9.msi C:\CiscoSource -Force
Start-Process Msiexec -Wait -ArgumentList '/package C:\CiscoSource\cisco-secure-client-win-5.1.6.103-sbl-predeploy-k9.msi /norestart /passive /qn /lvx* C:\CiscoSource\cisco-secure-client-win-5.1.6.103-sbl-predeploy-k9.log'

#Umbrella Roaming Security
Copy-Item .\cisco-secure-client-win-5.1.6.103-umbrella-predeploy-k9.msi C:\CiscoSource -Force
Start-Process Msiexec -Wait -ArgumentList '/package C:\CiscoSource\cisco-secure-client-win-5.1.6.103-umbrella-predeploy-k9.msi /norestart /passive /qn /lvx* C:\CiscoSource\cisco-secure-client-win-5.1.6.103-umbrella-predeploy-k9.log'
Copy-Item .\OrgInfo.json "$env:ProgramData\Cisco\Cisco Secure Client\Umbrella\" -Force

#Create version control file for Intune installer
New-Item -Path "C:\ProgramData\Cisco\Cisco Secure Client" -Name "intune_cisco_v5.1.6.103_install.txt" -ItemType "file"