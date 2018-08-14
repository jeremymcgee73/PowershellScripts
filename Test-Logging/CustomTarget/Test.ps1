@{
    Name = 'Test'
    Configuration = @{
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

        Write-Output "test"
    }
}