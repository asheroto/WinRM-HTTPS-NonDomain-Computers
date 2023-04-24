# Intro
Clear-Host
Write-Output "Run this on the SOURCE machine - the computer you are connecting from"
Write-Output ""
Write-Output "Running this script as Administrator is optional"
Write-Output ""
pause
Clear-Host

# Gather info and build URL
$target_hostname = Read-Host "Enter target hostname"
$target_username = Read-Host "Enter target username you'll use to authenticate (Administrator?)"
$target_url = "https://" + $target_hostname + ":5986/wsman"

# Append hostname to trusted hosts list
Write-Output ""
Write-Output "Appending $target_hostname to Trusted Hosts list"
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$target_hostname" -Concatenate -Force
Write-Output ""
Write-Output "Currently Trusted Hosts:"
(Get-Item WSMan:\localhost\Client\TrustedHosts).Value

# Explanation to save certificate
Write-Output ""
Write-Output "- A web browser will open"
Write-Output "- Save/export/copy the certificate (may be under Details tab of certificate) into CER format"
Write-Output "- Come back to this window afterwards"
Write-Output ""
pause
Start-Process $target_url

# Explanation to import certificate
Write-Output ""
Write-Output "- Double-click on the certificate exported to install it"
Write-Output "- Install/import the certificate into the Local Machine store location"
Write-Output "- Place certificate inside Trusted Root Certification Authorities store"
Write-Output "- Come back to this window afterwards"
Write-Output ""
pause

# Explanation to connect
Write-Output ""
Write-Output "- Connect using this command:"
Write-Output "      Enter-PSSession $target_hostname -UseSSL -Credential $target_username"
Write-Output ""

# Troubleshooting
Write-Output "- If you get an error when connecting, make sure you only have ONE certificate for the hostname"
Write-Output "- You must launch MMC and add the Certificates snap-in under the Computer Account to see the certs"
Write-Output "- Check the Trusted Root Certification Authorities store and delete any EXTRA certificates, don't delete anything else"
Write-Output ""
Write-Output "- Restart the machine if you have trouble"
Write-Output ""