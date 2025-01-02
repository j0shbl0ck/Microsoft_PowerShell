<#
    .NOTES
    =============================================================================
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 01.11.22
    Type: Public
    Source: https://docs.microsoft.com/en-us/powershell/scripting/samples/changing-computer-state?view=powershell-7.2
    Description: This script shows different prompts to restart or shut down the computer.  
    =============================================================================
#>

# Create menu with three options 
$menu = @{
    "Restart" = "Restart";
    "Restart Force" = "RestartForce";
    "Shutdown" = "Shutdown";
    "Exit" = "Exit";
}

# if user selects "Restart"
if ($menu.Restart) {
    # restart the computer
    Restart-Computer;
}

# if user selects "Restart Force"
if ($menu.RestartForce) {
    # restart the computer
    Restart-Computer -Force;
}

# if user selects "Shutdown"
if ($menu.Shutdown) {
    # shutdown the computer
    Shutdown-Computer;
}

# if user selects "Exit"
if ($menu.Exit) {
    # exit the script
    exit;
}
