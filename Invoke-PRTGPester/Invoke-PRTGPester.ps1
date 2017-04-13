param($ScriptPath)

Import-Module Pester

#You can find examples of the Advanced Sensor XML format in PRTG's API reference.
$XMLOutput = '<?xml version="1.0" encoding="Windows-1252" ?>'
$XMLOutput += "<prtg>`n"

(Invoke-Pester -Script $ScriptPath -PassThru -Show None).TestResult | ForEach-Object {

    $Describe = $_.Describe
    $Context = $_.Context
    $Name = $_.Name
    $Result = $_.Result
    $Value = 0

    #The passed value is 2, this is because PRTG doesn't handle boolean values very well. Greater than or equal to 1...
    if($Result -eq "Passed") {
        $Value = 2
    }

    #It could be helpful to add a Error Message, which PRTG does support.
    $XMLOutput += "<result>`n"
    #Really there is only one place in PRTG we can describe the Channel. So, I put the describe, context, and name in one field.
    $XMLOutput += "<channel>$Describe - $Context - $Name</channel>`n"
    $XMLOutput += "<value>$Value</value>`n"
    $XMLOutput += "<LimitMinError>1</LimitMinError>`n"
    $XMLOutput += "<limitmode>1</limitmode>`n"
    $XMLOutput += "</result>`n"

}
$XMLOutput += "</prtg>"

$XMLOutput
