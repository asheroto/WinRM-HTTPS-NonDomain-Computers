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
 1. Run `Target Computer Script.ps1` on the **Target**
 2. Restart the **Target** afterwards
 3. Run `Source Computer Script.ps1` on the **Source**