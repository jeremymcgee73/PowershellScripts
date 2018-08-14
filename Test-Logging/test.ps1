$Environment = "Production"
$Owner = "Testers"

$ErrorActionPreference = "Stop"

Import-Module Logging

Try {
    Set-LoggingCustomTarget -Path C:\scripts\Test-Logging\CustomTarget -Verbose
    Set-LoggingDefaultLevel -Level 'INFO'
    #Get-LoggingTargetAvailable

            
    Add-LoggingTarget -Name Console -Configuration @{}
    Add-LoggingTarget -Name Test -Configuration @{
            Owner = $Owner
            Path = $Path
            Environment = $Environment
    }
    if(!(Get-LoggingTargetAvailable).ContainsKey("Test")){
        "Test target does not exist"
    }
}Catch{
    "Error!"
    $_
}

#Test running this script by running '1 .. 100 |% { powershell -file "C:\scripts\Test-Logging\test.ps1"}' in the PS console.