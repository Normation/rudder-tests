param ($pubKey)
$sshFolder = "C:\ProgramData\ssh"

##### Install OpenSSH
$url = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.1.0.0p1-Beta/OpenSSH-Win64.zip"
$tmp = &{
  $parent = [System.IO.Path]::GetTempPath()
  [string] $name = [System.Guid]::NewGuid()
  Join-Path "${parent}" "${name}.zip"
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -OutFile $tmp $url -UseBasicParsing
$sshDir = "C:\Program Files\OpenSSH"
Add-Type -assembly "system.io.compression.filesystem"
[System.IO.Compression.ZipFile]::ExtractToDirectory($tmp, $sshDir)
powershell.exe -ExecutionPolicy Bypass -File "$sshDir/OpenSSH-Win64/install-sshd.ps1"
Set-Service sshd -StartupType Automatic

# Configure server
New-Item -ItemType Directory -Force -path $env:ProgramData\ssh
&"${sshDir}\OpenSSH-Win64\ssh-keygen.exe" -A
Copy-Item "${sshDir}\OpenSSH-Win64/sshd_config_default" "${sshFolder}\sshd_config"
"${pubKey}" | Out-File -Encoding utf8 -FilePath "${sshFOlder}\administrators_authorized_keys"

###### Set correct perms
&"${sshDir}\OpenSSH-Win64\FixHostFilePermissions.ps1" -Confirm:$false

# see https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-Win32-OpenSSH#host-private-key-files
$acl = Get-Acl "${sshFolder}\administrators_authorized_keys"
$acl.SetAccessRuleProtection($true, $false)
$administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
$systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM","FullControl","Allow")
$acl.SetAccessRule($administratorsRule)
$acl.SetAccessRule($systemRule)
$acl | Set-Acl

# Setup SSH firewall
Import-Module NetSecurity
$frule = Get-NetFirewallRule -DisplayName 'OpenSSH Server (sshd)'
if ($frule) {
  Write-output "Firewall rule already exists"
} else {
  Write-output "Creating new firewall rule for ssh server"
  New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}

# Set default shell
 New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
 New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShellCommandOption -Value "/c" -PropertyType String -Force

# Restart service
Start-Service sshd

