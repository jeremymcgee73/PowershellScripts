@{
    Name = 'Gelf'
    Configuration = @{
        GelfServer  = @{Required = $true;   Type = [string]}
        Port        = @{Required = $true;   Type = [int]}
        Level       = @{Required = $false;  Type = [string]}
        Format      = @{Required = $false;  Type = [string]}
        Owner       = @{Required = $true;  Type = [string]}
        Path        = @{Required = $true;  Type = [string]}
        Environment = @{Required = $true;  Type = [string]}
    }
    Logger = {
        param(
            $Log,
            $Format,
            [hashtable] $Configuration
        )

        Import-Module PSGELF
        
        $Params = @{}

        $Params['FilePath'] = Replace-Token -String $Configuration.Path -Source $Log

        Send-PSGelfUDP -GelfServer $Configuration.GelfServer `
        -Port $Configuration.Port `
        -ShortMessage $Log.message`
        -HostName $($env:computername  + "." + (Get-WmiObject Win32_ComputerSystem).Domain)`
        -DateTime $Log.timestamp`
        -AdditionalField @{
            Owner = $Configuration.Owner
            ScriptPath = $Configuration.Path
            Level = $Log.level
            Language = "PowerShell"
            Environment = $Configuration.Environment
        }

    }
}