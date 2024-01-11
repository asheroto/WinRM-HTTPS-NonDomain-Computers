#Requires -RunAsAdministrator

# WinRM HTTPS Configuration Script
# Source Machine Script
# Version 1.0.0
# This script will configure WinRM HTTPS on the source machine

# Set variables
$winrmHttpsPort = 5986

# Intro
Clear-Host
Write-Output "Source Machine Script"
Write-Output "---------------------"
Write-Output "After you've run Target-Machine.ps1 on the target machine, run this script on the source machine"
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
    Write-Warning "Target hostname is required"
    exit
}

# Verify connection to target
Write-Output "Verifying connection to $target_hostname"
if (Test-Connection -ComputerName $target_hostname -Count 1 -Quiet) {
    Write-Output "Connection to $target_hostname successful"
} else {
    Write-Warning "Connection to $target_hostname failed. Make sure you can ping the target machine."
    exit
}
$target_url = "https://" + $target_hostname + ":$winrmHttpsPort/wsman"

$target_username = Read-Host "Enter target username you'll use to authenticate [Administrator]"
# If not specified use Administrator
if ($target_username -eq "") {
    $target_username = "Administrator"
}

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
Write-Output ""

# Confirming port is open on target
Write-Output "Confirming port $winrmHttpsPort is open on $target_hostname"
function Test-Port {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Hostname,

        [Parameter(Mandatory = $false)]
        [int]$Port = 5986
    )

    $timeout = 2000
    Write-Output "Checking if port $Port is open on $Hostname..."

    $tcpClient = New-Object System.Net.Sockets.TcpClient

    try {
        $connect = $tcpClient.BeginConnect($Hostname, $Port, $null, $null)
        $success = $connect.AsyncWaitHandle.WaitOne($timeout, $false)
        $tcpClient.Close()

        if ($success) {
            Write-Output "Port $Port is open on $Hostname."
        } else {
            Write-Warning "Timeout occurred: Port $Port on $Hostname could not be reached after $timeout milliseconds."
            Write-Output "Make sure the target machine is configured correctly and that your connection is fast enough to support WinRM."
            exit
        }
    } catch {
        Write-Warning "Failed to connect: Port $Port is not open on $Hostname."
        Write-Output "Make sure the target machine is configured correctly."
        exit
    }
}
Test-Port -Hostname $target_hostname -Port $winrmHttpsPort

# Connect and save certificate
try {
    Write-Output "Downloading certificate from $target_url"
    $tcpClient = New-Object Net.Sockets.TcpClient($target_hostname, $winrmHttpsPort)
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
    Write-Warning "Cannot access $target_url"
    Write-Warning "Make sure the target machine is configured correctly."
    Write-Warning "Are you sure there is no connectivity issues between the two machines? Third-party firewall?"
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
Write-Output "You can connect to $target_hostname using the following command:"
Write-Output "`tEnter-PSSession $target_hostname -UseSSL -Credential $target_username"
Write-Output ""

# Test command
$doConnect = Read-Host "Do you want to test the connection using this command? (y/n)"
if ($doConnect -eq "y") {
    Write-Output ""
    Write-Output "Testing connection..."
    Enter-PSSession $target_hostname -UseSSL -Credential $target_username
}

# Additional information and warnings
Write-Output ("-" * 40)
Write-Output "Done!"