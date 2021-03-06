#This is designed to be ran on workstations, with admin rights. 
#We are pushing this out through PDQ Deploy. You could use a startup script deployed with a GPO, or maybe SCCM.
#This disables SMBv1 client and server on workstations

$OSversion = $(Get-WmiObject -Class Win32_OperatingSystem).caption

if($OSversion -like "*Windows 7*") {
    if((Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters").SMB1 -ne 0) {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" SMB1 -Type DWORD -Value 0 -Force
        sc.exe config lanmanworkstation depend= bowser/mrxsmb20/nsi
        sc.exe config mrxsmb10 start= disabled    
    }
}
elseif($OSversion -like "*Windows 10*"){
    if(Get-SmbServerConfiguration | Select -ExpandProperty EnableSMB1Protocol) {
        Set-SmbServerConfiguration -EnableSMB1Protocol $false
        sc.exe config lanmanworkstation depend= bowser/mrxsmb20/nsi
        sc.exe config mrxsmb10 start= disabled        
    }
}