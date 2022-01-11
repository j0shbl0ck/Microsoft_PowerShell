<#
    .NOTES
    =============================================================================
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 01.11.22
    Type: Public
    Source: https://docs.microsoft.com/en-us/powershell/scripting/samples/changing-computer-state?view=powershell-7.2
    Description: This script shows different prompts to restart or shut down the computer.  
    =============================================================================
#>

# To shut down the computer
Stop-Computer

# To restart the operating system
Restart-Computer

#To force an immediate restart of the computer
Restart-Computer -Force