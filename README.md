# Automatically Configure WinRM with HTTPS

[WinRM](https://learn.microsoft.com/en-us/windows/win32/winrm/portal) is a great tool for remotely managing Windows computers. It's built into Windows, and is easy to use. However, its configuration is not straightforward.

By default, all computers are in a workgroup. If you're using a personal computer, then you're on a workgroup. Most offices use a Windows domain, which helps with managing computers and users. Using WinRM on domain-joined computers is easy, but trying to configure WinRM on non-domain computers is a bit more complicated. You need to configure WinRM, its listener, firewall rules, an HTTPS certificate, and figure out the right commands to use. Sometimes `winrm quickconfig` has a bad day. 😆

These two little scripts make this whole process easy.

## Target audience

-   You want to use WinRM at home or at work, but don't want to use HTTP
-   You want to use WinRM with HTTPS, but don't have a Windows domain server
-   You're getting crazy errors when trying to use WinRM with HTTPS

## What does this do?

Automatically configures WinRM HTTPS on a target machine, and downloads the certificate to the source machine.

## Terms

-   **Source** - Computer you are connecting from (usually an Administrator computer)
-   **Target** - Computer you are connecting to (usually a server or another user's computer)

## Requirements:

-   PowerShell, preferably PowerShell 7 or higher
-   Administrative rights
-   LAN/VPN connectivity between the Source and Target
-   Windows 10/11 or Windows Server 2016/2019/2022

## Script Functionality

### `Target Machine Script.ps1`

-   Show you a list of network adapters and their categories
-   Allow you to select a network adapter to change to Private
-   Enable WinRM
-   Disable all default WinRM Rules
-   Create a firewall rule to allow WinRM HTTPS traffic on port 5986 from any IP address
-   Disable the HTTP listener if it exists
-   Create a self-signed HTTPS certificate
-   Create a WinRM HTTPS listener
-   Restart the WinRM service

### `Source Machine Script.ps1`

-   Prompt for the target hostname, and download the certificate
-   Import the certificate into the Trusted Root Certification Authorities store
-   Show you the command to connect to the target machine
-   Optionally test the connection

## Instructions

1. Run `Target Machine Script.ps1` on the **Target** and execute the command at the end of the script as instructed
2. Run `Source Machine Script.ps1` on the **Source** and perform the steps as instructed in the script

> [!WARNING]
> After running the source machine script, Make sure to adjust your Windows Firewall settings under the `Windows Remote Management (HTTPS-In)` rule to restrict access to the target machine as needed. By default, the rule allows all IP addresses to connect to the target machine. Other default rules are disabled.

## Useful WinRM related commands

### Get trusted hosts:

```powershell
Get-Item WSMan:\localhost\Client\TrustedHosts
```

or just the values

```powershell
(Get-Item WSMan:\localhost\Client\TrustedHosts).Value
```

### Trust all hosts:

```powershell
Set-Item WSMan:localhost\client\trustedhosts -Value *
```

### Set trusted hosts:

```powershell
Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'machineA,machineB'
```

### Append trusted hosts:

```powershell
Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'machineC' -Concatenate
```

### Remove a trusted host:

1. Get the list of trusted hosts
2. Adjust the command separated list as needed, removing the unneeded host
3. Use the commands to set the trusted hosts

### Enumerate WinRM listeners:

```powershell
winrm enumerate winrm/config/listener
```

### Check the state of configuration settings:

```powershell
winrm get winrm/config
```

## Links

[WinRM on Wikipedia](https://en.wikipedia.org/wiki/Windows_Remote_Management)
[Installation and Configuration for Windows Remote Management](https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management)
[WinRM Guide](https://www.comparitech.com/net-admin/winrm-guide/)

## Troubleshooting

As always, restart the computer (both) and try again. 🤓

## Contributing

If you'd like to help develop this project: fork the repo, edit, then submit a pull request. 😊