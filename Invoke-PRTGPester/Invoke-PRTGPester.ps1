param(
    #The path to the pester script or folder to run
    [Parameter(Mandatory)][System.IO.FileInfo]$ScriptPath,
    #The "working directory" where the path is, if specifying a relative path. Defaults to a folder named "pester" in the PRTG custom sensors directory
    [System.IO.FileInfo]$ScriptFolder = "Custom Sensors\pester",
    #Where to save the Pester Custom Lookup Definition. Defaults to {PRTG Install}\lookups\custom\powershell.pester
    [System.IO.FileInfo]$PesterLookupPath = "lookups\custom\powershell.pester",
    #Name of individual test or tests to run
    [String[]]$TestName,
    #Test Tags to run
    [String[]]$Tag,
    #Test Tags to Exclude
    [String[]]$ExcludeTag,
    #Don't compress the JSON. Leaves it more readable and is useful for debugging
    [Switch]$SkipCompressJSON,
    #Force certain actions, such as run even if PRTG isn't installed on the computer
    [Switch]$Force
)

Import-Module Pester

#region helpers

$pesterCustomLookupDefinition = @"
<?xml version="1.0" encoding="UTF-8"?>
  <ValueLookup id="powershell.pester" desiredValue="0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="PaeValueLookup.xsd">
    <Lookups>
      <SingleInt state="OK" value="0">
        Passed
      </SingleInt>
      <SingleInt state="Error" value="1">
        Failed
      </SingleInt>
      <SingleInt state="None" value="2">
        Skipped
      </SingleInt>
      <SingleInt state="Warning" value="3">
        Pending
      </SingleInt>
      <SingleInt state="Warning" value="4">
        Inconclusive
      </SingleInt>
    </Lookups>
  </ValueLookup>
"@

function Write-PRTGError($ErrorText) {
    $result = @{}
    $result.prtg = @{}
    $result.prtg.error = 1
    $result.prtg.text = $ErrorText
    $result | convertto-json
}
function New-PRTGResultSet {
    $result = @{}
    $result.prtg = @{}
    $result.prtg.result = New-Object System.Collections.Arraylist
    $result
}

function Add-PRTGPesterResult {
    param(
        #A TestResult object from Pester
        [Parameter(Mandatory,ValueFromPipeline)]$pesterResultObject,
        #A PRTG Result set created by New-PRTGResultSet
        $PRTGResultSet = (New-PRTGResultSet)
    )
    begin {
        $testErrors = @()
    }

    process {
        foreach ($pesterResultObjectItem in $pesterResultObject) {
            $result = @{
                Channel = ($pesterResultObjectItem.describe,$pesterResultObjectItem.context,$pesterResultObjectItem.name | Where-Object {$PSItem}) -join '-'
                ValueLookup = "powershell.pester"
                Value = switch ($pesterResultObjectItem.result) {
                    "Passed" {0}
                    "Failed" {1}
                    "Skipped" {2}
                    "Pending" {3}
                    "Inconclusive" {4}
                    default {4}
                }
            }

            if ($pesterResultObjectItem.failuremessage) {
                $testErrors += $result.channel,$pesterResultObjectItem.failuremessage -join ": "
            }

            $PRTGResultSet.prtg.result.add($result) | Out-Null
        }
    }

    end {
        if ($testErrors) {
            if ($prtgResultSet.text) {
                $testErrors += $prtgResultSet.prtg.text
            }
            $prtgResultSet.prtg.text = $testErrors -join ', '
        }
        $PRTGResultSet
    }
}
#endregion Helpers

#region Main

#Detect PRTG Installation
try {
    $PRTGInstallPath = (Get-ItemProperty 'HKLM:\Software\Wow6432Node\Paessler\PRTG Network Monitor' -erroraction stop).exepath
} catch {
    if (-not $Force) {
        write-PRTGError "Could not detect a PRTG installation on the probe this script was run. Install PRTG or re-run with -Force if just testing"
        exit 2
    } else {
        $prtgInstallPath = (pwd).path
    }
}

#Verify ScriptFolder. Set it to current directory if not found
if (-not (test-path $ScriptFolder)) {
    if ($PRTGInstallPath) {
        $ScriptFolder = join-path $PRTGInstallPath $ScriptFolder
    } else {
        $ScriptFolder = (pwd).path
    }
}

#Deploy the definition file if it is not already present
$PesterLookupPath = join-path $PRTGInstallPath $PesterLookupPath
$PesterLookupDirectory = split-path $pesterLookupPath -Leaf
if (-not (test-Path $PesterLookupPath) -and (-not $Force)) {
    write-prtgerror "Could not find Pester Lookup file at $PesterLookupPath. Creating it. Please refresh PRTG lookups in the System Administration tool and re-check this sensor"
    $pesterCustomLookupDefinition | Out-File $PesterLookupPath -ErrorAction SilentlyContinue
    exit 1
}

#Find the Pester script or folder to run
if (-not (test-path $ScriptPath)) {
    if (-not (test-path (join-path $ScriptFolder $ScriptPath))) {
        Write-PRTGError "Could not find $ScriptPath either directly or in $ScriptFolder, please check the path in the script definition."
        exit 2
    } else {
        $ScriptPath = join-path $ScriptFolder $ScriptPath
    }
}

#Prepare the pester command parameters
$invokePesterParams = @{}
foreach ($paramItem in "TestName","Tag","ExcludeTag") {
    $paramValue = Get-Variable -ValueOnly $paramItem -ErrorAction silentlycontinue
    if ($paramValue) {
        $invokePesterParams.$ParamItem = $paramValue
    }
}

$pesterResult = Invoke-Pester -Script $ScriptPath -PassThru -Show None @invokePesterParams
$PRTGResultSet = $pesterResult.TestResult | Add-PRTGPesterResult

#Create the "Failed Tests" primary channel and set sensor-level status
$PRTGFailedTestsResult = @{
    Channel = "Failed Tests"
    LimitMode = "1"
    LimitMaxError = "0"
    Unit = "Custom"
    CustomUnit = "Tests"
    Value = $pesterResult.failedcount
}

#Prepend the primary channel to the already returned results
$PRTGResultSet.prtg.result.insert(0,$PRTGFailedTestsResult)
if ($pesterResult.FailedCount) {
    $PRTGResultSet.prtg.text = "$(split-path $scriptPath -Leaf): $($pesterResult.passedCount) Passed, $($pesterResult.failedCount) Failed, $($pesterResult.totalCount) Total",$PRTGResultSet.prtg.text -join ' - '
}

$ConvertJSONParams = @{
    Depth = 4
    Compress = $true
}
if ($SkipCompressJSON) {
    $PRTGResultSetParams = $ConvertJSONParams.Compress=$false
}
$PRTGResultSet | ConvertTo-JSON @ConvertJSONParams
#endregion Main
