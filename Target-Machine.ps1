#Requires -RunAsAdministrator

# WinRM HTTPS Configuration Script
# Target Machine Script
# Version 1.0.0
# This script will configure WinRM HTTPS on the target machine

# Set variables
$winrmHttpPort = 5985
$winrmHttpsPort = 5986

# Intro
Clear-Host
Write-Output "Target Machine Script"
Write-Output "---------------------"
Write-Output "Run this script on the target machine, then run Source-Machine.ps1 on the source machine"
Write-Output ""
Write-Output "This script will do the following:"
Write-Output "- Show you a list of network adapters and their categories"
Write-Output "- Allow you to select a network adapter to change to Private"
Write-Output "- Enable WinRM"
Write-Output "- Disable all default WinRM Rules"
Write-Output "- Create a firewall rule to allow WinRM HTTPS traffic on port $winrmHttpsPort from any IP address"
Write-Output "- Disable the HTTP listener if it exists"
Write-Output "- Create a self-signed HTTPS certificate (valid for 15 years)"
Write-Output "- Create a WinRM HTTPS listener"
Write-Output "- Restart the WinRM service"
Write-Output ""
Pause

# Set network adapter category
Write-Output ""
Write-Output "In order for WinRM to work, the network adapter category must be set to Private"
Write-Output "Current network adapters and their categories:"

# Retrieve and display network adapter information in a table format
$adapters = Get-NetConnectionProfile
$adapters | Format-Table -AutoSize -Property @{Label = "Number"; Expression = { $adapters.IndexOf($_) + 1 } }, InterfaceAlias, NetworkCategory, IPv4Connectivity, IPv6Connectivity, InterfaceIndex

# User input to select the adapter
Write-Output "Type the number of the network adapter you want to change to Private"
$selectedNumber = Read-Host "Enter number"
$selectedAdapter = $adapters[$selectedNumber - 1]

# Check if the user selection is valid
if ($null -ne $selectedAdapter) {
    Write-Output "Changing the category of $($selectedAdapter.InterfaceAlias) to Private"
    Set-NetConnectionProfile -InterfaceAlias $selectedAdapter.InterfaceAlias -NetworkCategory Private
    Write-Output "Network category changed successfully"
} else {
    Write-Warning "Invalid selection. No changes made."
    exit
}

# Ensure default Windows Firewall rule exists so that Enable-PSRemoting works
Write-Output "Ensuring the default Windows Firewall rule exists so configuration can be applied"
$rule = Get-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -ErrorAction SilentlyContinue
if ($null -eq $rule) {
    Write-Output "Creating the default Windows Firewall rule (will be disabled later in the script)"
    New-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -Direction Inbound -LocalPort $winrmHttpPort -Protocol TCP -Action Allow -RemoteAddress LocalSubnet -Profile Private, Domain | Out-Null
} else {
    Write-Output "The default Windows Firewall rule already exists (will be disabled later in the script)"
}

# Enable remoting
Write-Output "Enabling WinRM"
Enable-PSRemoting -Force

# Disable all WinRM Rules that are not currently disabled
Write-Output "Disabling all default WinRM Rules"
$rules = Get-NetFirewallRule -DisplayName "Windows Remote Management*" | Where-Object { $_.Enabled -eq "True" }
if ($rules) {
    $rules | ForEach-Object { Disable-NetFirewallRule -DisplayName $_.DisplayName }
} else {
    Write-Output "No active Windows Firewall rules for WinRM were found"
}

# Create firewall rule
Write-Output "Creating firewall rule to allow WinRM HTTPS traffic on port $winrmHttpsPort from local subnet on Private or Domain profiles"
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Direction Inbound -LocalPort $winrmHttpsPort -Protocol TCP -Action Allow -RemoteAddress LocalSubnet -Profile Private, Domain | Out-Null

# Disable the HTTP listener if it exists
Write-Output "Disabling the HTTP listener"
$commandOutput = & winrm enumerate winrm/config/Listener | Select-String -Pattern "Transport = HTTP"
if ($commandOutput) {
    & winrm delete winrm/config/Listener?Address=*+Transport=HTTP
    Write-Output "HTTP listener disabled successfully"
} else {
    Write-Output "No HTTP listener found"
}

# Create self-signed certificate
Write-Output "Creating Self-Signed HTTPS Certificate"
$target_hostname = [System.Net.Dns]::GetHostName()
$expiration_date = (Get-Date).AddYears(15)
$target_thumbprint = $(New-SelfSignedCertificate -DnsName $target_hostname -CertStoreLocation Cert:\LocalMachine\My -NotAfter $expiration_date).Thumbprint

# Create HTTPS listener
Write-Output "Creating WinRM HTTPS listener"
$commandArguments = "create", "winrm/config/Listener?Address=*+Transport=HTTPS", "@{Hostname=`"$target_hostname`"; CertificateThumbprint=`"$target_thumbprint`"}"

# Execute the command and check for specific error
try {
    $commandOutput = & winrm $commandArguments 2>&1
    if ($commandOutput -match "-2144108493 0x80338033") {
        Write-Warning "A WinRM HTTPS listener already exists. Recreating it."
        & winrm delete winrm/config/Listener?Address=*+Transport=HTTPS
        $commandOutput = & winrm $commandArguments 2>&1
        Write-Output "Listener recreated successfully"
    }

    # Verify if the listener was created/recreated successfully
    $listener = winrm enumerate winrm/config/Listener
    if ($listener -match "Transport\s+= HTTPS" -and $listener -match "Hostname\s+= $target_hostname") {
        Write-Output "Listener created successfully"
    } else {
        Write-Warning "Failed to verify the listener creation. Some issue is interfering with the WinRM HTTPS listener creation."
        exit
    }
} catch {
    Write-Warning "An error occurred: $_"
    exit
}

# Restart WinRM service
Write-Output "Restarting WinRM service"
Restart-Service WinRM

# Additional information and warnings
Write-Output ("-" * 40)
Write-Output "Done! Now Run Source-Machine.ps1 on the source machine"
Write-Warning "By default, WinRM is accessible to all IP addresses in the local subnet. A username and password are required for connection, but for additional security, consider modifying the 'Windows Remote Management (HTTPS-In)' firewall rule."