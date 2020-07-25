param ($pubKey)
$sshFolder = "C:\ProgramData\ssh"

##### Install OpenSSH
$url = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.1.0.0p1-Beta/OpenSSH-Win64.zip"
$tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -OutFile $tmp $url
$tmpDir = [System.IO.Path]::GetTempPath()
$tmp | Expand-Archive -DestinationPath $tmpDir -Force
cd $tmpDir/OpenSSH-Win64
powershell.exe -ExecutionPolicy Bypass -File install-sshd.ps1
Set-Service sshd -StartupType Automatic

# Configure server
./ssh-keygen.exe -A
Copy-Item .\sshd_config_default "${sshFolder}\sshd_config"
"${pubKey}" | Out-File -Encoding utf8 -FilePath "${sshFOlder}\administrators_authorized_keys"

###### Set correct perms
C:\Users\Administrator\AppData\Local\Temp\OpenSSH-Win64\FixHostFilePermissions.ps1 -Confirm:$false

# see https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-Win32-OpenSSH#host-private-key-files
$acl = Get-Acl "${sshFolder}\administrators_authorized_keys"
$acl.SetAccessRuleProtection($true, $false)
$administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
$systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM","FullControl","Allow")
$acl.SetAccessRule($administratorsRule)
$acl.SetAccessRule($systemRule)
$acl | Set-Acl

# Setup SSH firewall
$frule = Get-NetFirewallRule -DisplayName 'OpenSSH Server (sshd)'
if ($frule) {
  Write-output "Firewall rule already exists"
} else {
  Write-output "Creating new firewall rule for ssh server"
  New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}
# Restart service
Start-Service sshd
