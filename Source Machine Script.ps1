#Requires -RunAsAdministrator

# WinRM HTTPS Configuration Script
# Source Machine Script
# Version 1.0.0
# This script will configure WinRM HTTPS on the source machine

# Intro
Clear-Host
Write-Output "Source Machine Script"
Write-Output "---------------------"
Write-Output "Run this script second on the source machine, after running the target machine script on the target machine"
Write-Output "This script should be ran on the computer you are connecting from"
Write-Output ""
Write-Output "This script will do the following:"
Write-Output "- Prompt for the target hostname, and download the certificate"
Write-Output "- Import the certificate into the Trusted Root Certification Authorities store"
Write-Output "- Show you the command to connect to the target machine"
Write-Output "- Optionally test the connection"
Write-Output ""
Pause

# Gather info and build URL
Write-Output ""
$target_hostname = Read-Host "Enter target hostname"

# If not specified throw error
if ($target_hostname -eq "") {
    throw "Target hostname is required"
}

# Verify connection to target
Write-Output "Verifying connection to $target_hostname"
if (Test-Connection -ComputerName $target_hostname -Count 1 -Quiet) {
    Write-Output "Connection to $target_hostname successful"
} else {
    Write-Warning "Connection to $target_hostname failed. Make sure you can ping the target machine."
    exit
}

$target_username = Read-Host "Enter target username you'll use to authenticate [Administrator]"
# If not specified use Administrator
if ($target_username -eq "") {
    $target_username = "Administrator"
}
$target_url = "https://" + $target_hostname + ":5986/wsman"

# Convert hostname to lowercase
$target_hostname = $target_hostname.ToLower()

# Append hostname to trusted hosts list
$currentTrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value

Write-Output ""
Write-Output "Appending $target_hostname to Trusted Hosts list"

# Check if hostname already exists in Trusted Hosts
if ($currentTrustedHosts -like "*$target_hostname*") {
    Write-Output "$target_hostname is already in the Trusted Hosts list"
} else {
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$target_hostname" -Concatenate -Force
    Write-Output "$target_hostname added to Trusted Hosts."
}

Write-Output ""
Write-Output "Currently Trusted Hosts:"
(Get-Item WSMan:\localhost\Client\TrustedHosts).Value

# Connect and save certificate
try {
    Write-Output "Downloading certificate from $target_url"
    $tcpClient = New-Object Net.Sockets.TcpClient($target_hostname, 5986)
    $sslStream = New-Object Net.Security.SslStream($tcpClient.GetStream(), $false, { $true })
    $sslStream.AuthenticateAsClient($target_hostname)
    $certificate = $sslStream.RemoteCertificate
    $x509Cert = New-Object Security.Cryptography.X509Certificates.X509Certificate2($certificate)
    $certPath = New-TemporaryFile
    [IO.File]::WriteAllBytes($certPath, $x509Cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert))
    Write-Output ""
    Write-Output "Certificate saved to temp folder"
    $sslStream.Close()
    $tcpClient.Close()
} catch {
    Write-Warning "An error occurred while retrieving the certificate: $_"
    Write-Warning "Are you sure there is no connectivity issues between the two machines? Third-party firewall?"
    Write-Warning "If the issue persists, please open an issue on GitHub."
    exit
}

# Import the certificate using .NET
Write-Output ""
Write-Output "Importing certificate into Trusted Root Certification Authorities store"
$certStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
$certStore.Open("ReadWrite")
$certStore.Add($x509Cert)
$certStore.Close()

# Remove the certificate
Write-Output ""
Write-Output "Removing certificate from temp folder"
Remove-Item $certPath

# Explanation to connect
Write-Output ""
Write-Output "- Connect using this command:"
Write-Output "      Enter-PSSession $target_hostname -UseSSL -Credential $target_username"
Write-Output ""

# Test command
$doConnect = Read-Host "Do you want to test the connection? (y/n)"
if ($doConnect -eq "y") {
    Write-Output ""
    Write-Output "Testing connection..."
    Enter-PSSession $target_hostname -UseSSL -Credential $target_username
}

# Troubleshooting
Write-Output ""
Write-Output "If you cannot connect, please restart both computers and try again."
Write-Output "Please open an issue on GitHub if you have any questions or problems."