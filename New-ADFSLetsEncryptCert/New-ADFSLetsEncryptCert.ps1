<#
New-ADFSLetsEncryptCert is a script that creates a Let's Encrypt Cert for your ADFS server,
and updates your ADFS and WAP server's to use the new cert. This could be modified to updates
all of the servers in your farm.

I am currently only use this for a proof of concept. I would test this thoroughly before
using this in prod. It needs more error handling and alerting. Install the AWSpowerShell
and ACMESharep modules first. If you aren't using Route53 you will have to change
the way you do the Let's Encrypt Challenge. You must create your AWS Profile.
#>

Import-Module AWSPowerShell
Import-Module ACMESharp


$name = "adfs"
$AcmeIdent = $name + $(New-Guid)
$dns = "$name.yourcompany.com"
$certIdent = $name + "cert" + $(New-Guid)

$certPath = "C:\temp\certs\$name.pfx"

#First Run. Setup your Let's Encrypt Vault

if (!(Get-ACMEVault))
{
    Initialize-ACMEVault
    New-ACMERegistration -Contacts mailto:youremail@yourcomany.com -AcceptTos
}

try {
    #I am using Route 53 for DNS, ACME has AWS support, so that is how I do my challenge.

    $ACMEIdentifier = New-ACMEIdentifier -Dns $dns -Alias $AcmeIdent
    $AcmeChallenge = Complete-ACMEChallenge $AcmeIdent -ChallengeType dns-01 -Handler awsRoute53 -HandlerParameters @{ HostedZoneId = 'AWSzoneID'; AwsProfileName = 'your AWS profile name' }

    #Might be a better way to do this...
    Start-Sleep 30

    Submit-ACMEChallenge $AcmeIdent -ChallengeType dns-01
    Update-ACMEIdentifier $AcmeIdent

    New-ACMECertificate $AcmeIdent -Generate -Alias $certIdent
    Submit-ACMECertificate $certIdent
    Update-ACMECertificate $certIdent

    if(Test-Path $certPath) {
        Remove-Item $certPath -Force
    }

    #Export a pfx file
    Get-ACMECertificate $certIdent -ExportPkcs12 $certPath

} catch {
    $_
    Break
}


Try {
    #I believe WMF5.1 has Cmdlets for this. Instead of this mess.
    Add-Type -AssemblyName System.Security
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
    $cert.Import($certPath, $Password, $flags)
    $store = new-object system.security.cryptography.X509Certificates.X509Store -argumentlist "MY", LocalMachine
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::"ReadWrite")
    $store.Add($cert)
    $store.Close()

    #The thumbprint is how ADFS knows what cert you want to use.
    $Thumbprint = $cert.Thumbprint
}
Catch {
    $_
    Break
}

Try {
    Set-AdfsCertificate -CertificateType Service-Communications -Thumbprint $Thumbprint
    Set-AdfsSslCertificate -Thumbprint $Thumbprint
    Restart-Service adfssrv
}
Catch {
    $_
    Break
}

Try {
    #I would recommened saving these Secure Strings to a file instead of leaving them plain text.
    $secpasswd = ConvertTo-SecureString “PASSWORD HERE” -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential (“local user account”, $secpasswd)

    $WAP = New-PSSession -ComputerName wapdnsnameorIP -Credential $mycreds -Verbose

    Copy-Item $certPath -Destination "C:\temp\certs\" -ToSession $WAP
}
Catch {
    $_
    Break
}

$ImportCertScript = {
    #Imports the Cert
    $certPath = "C:\temp\certs\adfs.pfx"

    Add-Type -AssemblyName System.Security
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
    $cert.Import($certPath, $Password, $flags)
    $store = new-object system.security.cryptography.X509Certificates.X509Store -argumentlist "MY", LocalMachine
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::"ReadWrite")
    $store.Add($cert)
    $store.Close()

    #The thumbprint ADFS needs 
    $Thumbprint = $cert.Thumbprint

    #I would recommened saving these Secure Strings to a file instead of leaving them plain text.
    $secpasswd = ConvertTo-SecureString “YOUR PASSWORD” -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential (“domain\username”, $secpasswd)

    Install-WebApplicationProxy -CertificateThumbprint $Thumbprint -FederationServiceName 'adfs.yourcompany.com' -FederationServiceTrustCredential $mycreds
    Restart-Service appproxysvc

}

Invoke-Command -ScriptBlock $ImportCertScript -Session $WAP