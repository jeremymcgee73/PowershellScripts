Import-Module CNPSLogger

Use-CNPoshLogging -Owner "Infrastructure" -Environment "Testing" -ScriptPath "C:\scripts\example.ps1"

Try{
    Get-ChildItem "C:\balsdfsdfsd" -ErrorAction Stop
}Catch{
    Write-Log -Message $(New-ErrorString $_) -Level ERROR

    #If you want to stop the script use this function.
    Exit-CNPoshLogging
}

#The logging module uses a seperate thread, this makes sure all logs are written before exiting.
Wait-Logging
