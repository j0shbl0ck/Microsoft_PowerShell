<#
    .NOTES
    =============================================================================
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 01.11.22
    Type: Public
    Source: 
    Description: This script produces the devices serial number. 
    =============================================================================
#>

Get-WmiObject win32_bios | Select-Object Serialnumber