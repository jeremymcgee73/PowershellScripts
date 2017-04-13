$ServerName = "FileServer"
$Session = New-CimSession -ComputerName $ServerName

$critServices = @( 'DHCP', 'DNSCache', 'Eventlog', 'RpcSs', 
    'Server', 'lanmanserver', 'LmHosts', 'Lanmanworkstation', 'MpsSvc', 'WinRM')

 
Describe "FileServer Configuration Tests" {

    Context 'FileServer Server Configuration' {
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