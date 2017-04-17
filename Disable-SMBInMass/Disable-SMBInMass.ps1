#This is a quick script I wrote to disable SMBv1 on Server 2008, and remove it on Server 2012
#You must reboot after!
Get-ADComputer -filter * -SearchBase "OU=Systems,DC=your,DC=domain" | ForEach-Object {
    $HostName = $_.DNSHostName
    $OSversion = $(Get-WmiObject -Computer $HostName -Class Win32_OperatingSystem).caption

    $_.DNSHostName

    if($OSversion -like "Microsoft Windows Server 2008 R2*") {
        Invoke-Command -ScriptBlock {Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" SMB1 -Type DWORD -Value 0 –Force} -ComputerName $HostName
    }
    elseif($OSversion -like "*2012 R2*"){
        if(@(Get-WindowsFeature -ComputerName $HostName -Name FS-SMB1).Count -eq 1) {
            Remove-WindowsFeature FS-SMB1 -ComputerName $HostName
        }
    }
    
}