# Automatically Configure WinRM with HTTPS

[WinRM](https://learn.microsoft.com/en-us/windows/win32/winrm/portal) is a great tool for remotely managing Windows computers. It's built into Windows, and is easy to use. However, its configuration is not straightforward.

By default, all computers are in a workgroup. If you're using a personal computer, then you're on a workgroup. Most offices use a Windows domain, which helps with managing computers and users. Using WinRM on domain-joined computers is easy, but trying to configure WinRM on non-domain computers is a bit more complicated. You need to configure WinRM, its listener, firewall rules, an HTTPS certificate, and figure out the right commands to use.

Sometimes `winrm quickconfig` has a bad day. 😆

These two little scripts make this whole process easy.

## Target audience

-   You want to use WinRM at home or at work, but don't want to use HTTP
-   You want to use WinRM with HTTPS, but don't have a Windows domain server
-   You're getting crazy errors when trying to use WinRM with HTTPS

## Definitions

| Term            | Definition                                                                                                                                                                                                                                                                                                                    |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Source**      | The computer you are connecting from (typically an Administrator's computer).                                                                                                                                                                                                                                                 |
| **Target**      | The computer you are connecting to (usually a server or another user's computer).                                                                                                                                                                                                                                             |
| **HTTP**        | Hypertext Transfer Protocol (HTTP) is used for transmitting data over a network. It is unencrypted and insecure. Information is transmitted over the network in plain text.                                                                                                                                                   |
| **HTTPS**       | Hypertext Transfer Protocol Secure (HTTPS) is HTTP encrypted using TLS or SSL. Used for secure communication over a network.                                                                                                                                                                                                  |
| **Listener**    | A WinRM listener responds to WinRM service requests. Defined by IP address, port, and protocol (HTTP/HTTPS, IPv4/IPv6). Can listen on any or specific IP address and port.                                                                                                                                                    |
| **Certificate** | A digital certificate is essential for enabling HTTPS encryption. It certifies the ownership of a public key by the certificate's subject, allowing secure communication through encryption. Issued by a Certificate Authority (CA) or self-signed, it links the public key with its owner and provides identity information. |

## WinRM Networking

-   WinRM uses port 5985 for HTTP and port 5986 for HTTPS.
-   You can change the ports if you want, but it's not recommended.
-   For HTTPS connections, WinRM listens on `https://HOSTNAME:5986/wsman`.
-   Below is a _very_ simplified representation of WinRM's network traversal so you can understand what's happening when you initiate a WinRM connection from PowerShell. Certain steps are omitted for simplicity such as the source computer, TLS/SSL negotiation, etc.
    ![WinRM traversal](https://github.com/asheroto/WinRM-HTTPS-NonDomain-Computers/assets/49938263/ef3d998c-86a1-4321-a3b4-08c23b6179c4)

## Requirements

-   PowerShell
-   Administrative rights
-   LAN/VPN connectivity between the Source and Target
-   Windows 10/11 Pro or Windows Server 2016/2019/2022

## Script Functionality

### `Target-Machine.ps1`

-   Shows you a list of network adapters and their categories.
-   Allows you to select a network adapter to change to Private.
-   Enables WinRM.
-   Disables all default WinRM Rules.
-   Creates a firewall rule to allow WinRM HTTPS traffic on port 5986 from any IP address.
-   Disables the HTTP listener if it exists.
-   Creates a self-signed HTTPS certificate (valid for 15 years).
-   Creates a WinRM HTTPS listener.
-   Restarts the WinRM service.

### `Source-Machine.ps1`

-   Prompts for the target hostname, and downloads the certificate.
-   Imports the certificate into the Trusted Root Certification Authorities store.
-   Shows you the command to connect to the target machine.
-   Optionally tests the connection.

## Usage

> [!WARNING]
> Do **NOT** expose a machine with WinRM enabled to the internet. WinRM is not designed to be secure enough for internet use. If you need to use WinRM over the internet, use a VPN.

### Step 1

-   Run `Target-Machine.ps1` on the **Target** machine, which is the computer you want to connect to
-   Windows Firewall allows all local subnet IPs to access WinRM. To change this, edit the 'Windows Remote Management (HTTPS-In)' firewall rule.

### Step 2

-   Run `Source-Machine.ps1` on the **Source**, which is the computer you want to connect from

## Rationale

### Why not use HTTP?

HTTP is insecure. It's not encrypted, and it's not authenticated. In terms of WinRM, it means anyone can see the data you're sending and receiving. This is a security risk, and is not recommended.

But at home?

Yes! Even at home. If you're using WinRM at home, you may be using it to manage a server or another computer. Sure, you may trust the other people in your home, but do you trust all of the other devices in your home? What about that smart TV, or that smart fridge? What about that smart lightbulb? Although it's unlikely, it could be possible for a malicious actor to intercept your WinRM traffic, see what you're doing, then gain access to your computers, servers, and data.

### Why generate a new self-signed certificate?

![self-signed certificate](https://github.com/asheroto/WinRM-HTTPS-NonDomain-Computers/assets/49938263/5c2e2ed3-4e83-4461-97d6-3f395b7381a1)

Creating a new self-signed certificate effectively severs the dependence on existing certificates. It establishes a dedicated certificate exclusively for WinRM use, eliminating the need to repurpose or create additional certificates for your computer. Moreover, self-signed certificates provide the convenience of easy removal when required.

In future versions this functionality may be expanded to allow the use of existing certificates.

### Why not use Kerberos authentication?

[Kerberos authentication](https://www.upguard.com/blog/kerberos-authentication) is a great way to authenticate users and computers on a Windows domain. However, it's not available for non-domain computers. If you're using WinRM at home or at work on a non-domain computer, you can't use Kerberos authentication.

### Why are you creating _new_ firewall rules?

By creating new firewall rules rather than modifying existing ones, it allows us to ignore any potential misconfigurations or issues with existing rules. It also allows us to easily remove the rules if needed. Default rules are not deleted but simply disabled.

### Why not make this available on PowerShell Gallery?

It will be soon!

## Useful WinRM related commands

### Get trusted hosts

```powershell
Get-Item WSMan:\localhost\Client\TrustedHosts
```

or just the values

```powershell
(Get-Item WSMan:\localhost\Client\TrustedHosts).Value
```

### Trust all hosts

```powershell
Set-Item WSMan:localhost\client\trustedhosts -Value *
```

### Set trusted hosts

```powershell
Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'machineA,machineB'
```

### Append trusted hosts

```powershell
Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'machineC' -Concatenate
```

### Remove a trusted host

1. Get the list of trusted hosts
2. Adjust the command separated list as needed, removing the unneeded host
3. Use the commands to set the trusted hosts

### Enumerate WinRM listeners

```powershell
winrm enumerate winrm/config/listener
```

### Check the state of configuration settings

```powershell
winrm get winrm/config
```

## Troubleshooting

-   As always, restart the computer (both) and try again. 🤓
-   Make sure you can ping the computers both ways. Use IP addresses first, then try hostnames.
-   Test the connectivity using [Test-NetConnection](https://lazyadmin.nl/powershell/test-netconnection/).
    -   `Test-NetConnection -ComputerName HOSTNAME -Port 5986 -InformationLevel Detailed`
-   As a test of _some_ port accessibility, enable RDP on the target machine and see if you can connect.
    -   If RDP is enabled and you can't connect over RDP, then the issue is unrelated WinRM as is likely a network/firewall issue.
    -   The reason for this test is that RDP reliably enables firewall rules and opens ports.
-   If you are unable to connect, try _temporarily_ disabling Windows Firewall on the target machine (only if it is safe to do so).
    -   If you can connect after disabling Windows Firewall — good news! — simply adjust the Windows Firewall rules!
-   [Enumerate](#enumerate-winrm-listeners) the WinRM listeners on the target machine.
    -   If you don't see a listener, then for some reason the `Target-Machine.ps1` script failed to create it.
    -   You can try running the script again, or manually creating the listener.
    -   If you see an error message please [open an issue](issues) and include the full error message so that that script can be improved.

## TODO

-   Create consistent grammar for the script output
-   Add a check for the WinRM service
-   More options for security on firewall, listener configuration, and certificate creation
-   Ability to use existing certificate, listener, and/or firewall rule

## Contributing

If you'd like to help develop this project: fork the repo, edit, then submit a pull request. 😊

## Links

-   [WinRM on Wikipedia](https://en.wikipedia.org/wiki/Windows_Remote_Management)
-   [Installation and Configuration for Windows Remote Management](https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management)
-   [WinRM Guide](https://www.comparitech.com/net-admin/winrm-guide/)