# **HTTPS with WinRM on Non-Domain Computers**
These two little scripts make this whole process easy.

Automatically configure firewall rules, SSL certificates, and obtain a command to connect.

Follow these instructions and the scripts will explain further.  

## Requirements:
- PowerShell
- Administrative rights
- LAN connectivity between computers (or via VPN)
- Port Forwarding possible but not recommended due to security risks

## Terms:
- **Source** - Computer you are connecting from (usually an Administrator computer)
- **Target** - Computer you are connecting to (usually a user's computer or server)

## Instructions:
 1. Run `Target Computer Script.ps1` on the **Target** and execute the command at the end of the script as instructed
 2. Restart the **Target** afterwards
 3. Run `Source Computer Script.ps1` on the **Source** and perform the steps as instructed in the script

---

## Other useful WinRM related commands

### Get trusted hosts:
`Get-Item WSMan:\localhost\Client\TrustedHosts`

### Trust all hosts:
`Set-Item WSMan:localhost\client\trustedhosts -Value *`

### Set trusted hosts:
`Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'machineA,machineB'`

### Append trusted hosts:
`Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'machineC' -Concatenate`

### Remove a trusted host:
1. Get the list of trusted hosts
2. Adjust the command separated list as needed, removing the unneeded host
3. Use the commands to set the trusted hosts