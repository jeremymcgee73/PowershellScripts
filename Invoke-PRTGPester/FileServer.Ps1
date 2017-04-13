$ServerName = "FileServer"
$Session = New-CimSession -ComputerName $ServerName

$critServices = @( 'DHCP', 'DNSCache', 'Eventlog', 'RpcSs', 
    'Server', 'lanmanserver', 'LmHosts', 'Lanmanworkstation', 'MpsSvc', 'WinRM')

$sysDriveLetter = $env:SystemDrive.Substring(0,1)
$freeSysDriveThreshold = 500
$freeNonSysDriveThreshold = 500
$freeNonSysDriveThresholdPct = .05
$freeMemThreshold = 500


 
Describe "FileServer Configuration Tests" {

    Context 'FileServer Server Configuration' {
        It "Should not have a pending reboot." {
                (Test-PendingReboot.ps1 $ServerName).IsPendingReboot | Should BeExactly $False
        }
        It "Should not have any DHCP IPs." {
               @(Get-NetAdapter -CimSession $Session | ? status -eq ‘up’ | Get-NetIPAddress -AddressFamily IPv4 -CimSession $Session | Where-Object {$_.PrefixOrigin -eq "Dhcp"}).Count | Should BeExactly 0
        }
    }    

    Context 'Critical Services' {
        foreach ($svc in $critServices) {
            it "[$svc] Service running" {
                $svcInst = Get-Service -Name $svc -ComputerName $ServerName
                $svcInst.Status | should be 'Running'    
            }            
        }
    }

    Context 'Memory' {
        it "Has $freeMemThreshold MB of RAM free" {
            $os = Get-CimInstance -ClassName 'win32_operatingsystem'
            $os.FreePhysicalMemory -ge $freeMemThreshold | should be $true
        }
    }

    Context 'Storage' {

        it "System drive [$sysDriveLetter] has $freeSysDriveThreshold MB free" {            
            $sysDrive = Get-Volume -DriveLetter $sysDriveLetter
            ($sysDrive.SizeRemaining / 1MB) -ge $freeSysDriveThreshold | should be $true
        }
        
        $volumes = Get-Volume | where DriveType -eq 'Fixed'
        foreach ($volume in $volumes | where DriveLetter -ne $sysDriveLetter) {
            it "Non-System drive [$($volume.DriveLetter)] has greater than $freeNonSysDriveThreshold MB free" {
                ($volume.SizeRemaining / 1MB) -ge $freeNonSysDriveThreshold | should be $true
            }
            
            it "Non-System drive [$($volume.DriveLetter)] has greater than $freeNonSysDriveThresholdPct% free" {
                ($volume.SizeRemaining / $volume.Size) -ge $freeNonSysDriveThresholdPct | should be $true
            }
        }
    }
    
 
    Context 'FileServer Share Configuration' {
        It "Should have an Applications share" {
            @(Get-SmbShare applications -ErrorAction SilentlyContinue -CimSession $Session).Count | Should BeExactly 1
        }

        It "Should have an Workgroups share" {
            @(Get-SmbShare workgroups -ErrorAction SilentlyContinue -CimSession $Session).Count | Should BeExactly 1
        }

        It "Should have an Workgroups share" {
            @(Get-SmbShare Home -ErrorAction SilentlyContinue -CimSession $Session).Count | Should BeExactly 1
        }

    }


 
} # Describe
 
Remove-CimSession $Session