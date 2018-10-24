Import-Module Logging
Import-Module PSGELF

function New-ErrorString ($thisError) {
    [string] $Return = $thisError.Exception
    $Return += "`r`n"
    $Return += "At line:" + $thisError.InvocationInfo.ScriptLineNumber
    $Return += " char:" + $thisError.InvocationInfo.OffsetInLine
    $Return += " For: " + $thisError.InvocationInfo.Line
    Return $Return
}

function Use-CNPoshLogging 
{
    Param (
        [Parameter(Mandatory=$True)][string]$Owner,
        [Parameter(Mandatory=$True)][string]$Environment,
        [Parameter(Mandatory=$True)][string]$ScriptPath,
        [Parameter(Mandatory=$False)][string]$LogPath
    )
    Process
    {
        $ErrorActionPreference = "Stop"
        $ModulePath = (Get-Module -ListAvailable CNPSLogger).ModuleBase + "/Target"

        Set-LoggingCustomTarget -Path $ModulePath -Verbose

        Set-LoggingDefaultLevel -Level 'INFO'
            
        Add-LoggingTarget -Name Console -Configuration @{}
        Add-LoggingTarget -Name Gelf -Configuration @{
                GelfServer = 'Graylog' 
                Port = 12201
                Owner = $Owner
                Path = $ScriptPath
                Environment = $Environment
        }

        if($LogPath) {
            $ScriptName = ($ScriptPath -Split "\\")[-1]
            $LogPathWithScript = $LogPath + $ScriptName + "_%{+%Y%m%d}.log"
            Add-LoggingTarget -Name File -Configuration @{Path = $LogPathWithScript}   
        }      
    }
}

#This is used to stop a script but make sure the log is written.
function Exit-CNPoshLogging () {
    Wait-Logging
    Break Script
}