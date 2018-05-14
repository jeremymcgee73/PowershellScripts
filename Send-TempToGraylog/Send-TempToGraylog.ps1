$ErrorActionPreference = "Stop"
$HostName = "tempsensor.yourdomain.com"

Try {
    Import-Module PowerShell.IoT.TMP102
    Import-Module PSGELF

    $temp = Get-TMP102Temp
    Send-PSGelfUDP -GelfServer graylog.yourdomain.com `
        -Port 12201 `
        -HostName $HostName `
        -ShortMessage "The temp in Farenheit is $($temp.Fahrenheit)" `
        -AdditionalField @{temperature = $temp.Fahrenheit}
} Catch {
    #Send an email, if there are any other errors in the script.
    Send-MailMessage `
        -From "sysadmin@yourdomain.com" `
        -To 'jmcgee@yourdomain.com' `
        -Subject "An error occured with a Temp Sensor $HostName" `
        -BodyAsHtml "<p>There was an issue with the tempsensor $HostName.<br /> $($_) </p>" `
        -SmtpServer smtp.yourdomain.com
    
    $_
}