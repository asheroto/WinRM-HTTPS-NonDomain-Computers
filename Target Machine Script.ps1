# Intro
Clear-Host
Write-Output "Run this on the TARGET machine - the computer you want to connect to"
Write-Output "MUST RUN THIS SCRIPT AS ADMINISTRATOR"
Write-Output ""
Write-Output "This script will:"
Write-Output "- Set the category of your network adapters to Private"
Write-Output "- Create the necessary firewall rules"
Write-Output "- Generate a self-signed certificate"
Write-Output "- Enable WinRM and create a WinRM HTTPS listener"
Write-Output ""
pause
Clear-Host

# Set network adapter category
$networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
$connections = $networkListManager.GetNetworkConnections()
$connections | ForEach-Object { $_.GetNetwork().SetCategory(1) }

# Create firewall rule
New-NetFirewallRule -DisplayName WinRM -RemoteAddress Any -Direction Inbound -Profile Any -Protocol TCP -LocalPort 5985-5986

# Enable remoting
Enable-PSRemoting -Force

# Generate commands to execute
$target_hostname = [System.Net.Dns]::GetHostName()
$target_thumbprint = $(New-SelfSignedCertificate -DnsName $target_hostname -CertStoreLocation Cert:\LocalMachine\My).Thumbprint
$invoke_command = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=""$target_hostname""; CertificateThumbprint=""$target_thumbprint""}'"

# Explain to execute commands
Write-Output ""
Write-Output "Copy this line then execute:"
Write-Output "      $invoke_command"
Write-Output ""
Write-Output "If you already have a listener and get an error running the above command,"
Write-Output "copy this line and execute then try above line again:"
Write-Output "      winrm delete winrm/config/Listener?Address=*+Transport=HTTPS"
Write-Output ""