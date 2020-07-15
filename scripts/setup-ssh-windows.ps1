# !!!!! Not a real script
# View this file as a list of command to type
Enable-PSRemoting -Force
netsh advfirewall firewall add rule name="SSH server" dir=in localport=22 protocol=TCP action=allow

# Windows 2019 embedded ssh server
# ================================
$ssh_folder = "C:\\Users\\Administrator\\.ssh"
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
New-Item -ItemType directory -Path $ssh_folder
# get the public key in ruby with
# public_key = %x[ssh-keygen -y -f #{$AWS_KEYPATH}]
'#{public_key}' | Out-File $ssh_folder\\authorized_keys -encoding utf8
# this does not seem to work
New-ItemProperty -Path 'HKLM:\\SOFTWARE\\OpenSSH' -Name DefaultShell -Value 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe' -PropertyType String -Force


# Other versions : install Win32 portable openssh
# ===============================================
# Doc: https://github.com/powershell/Win32-OpenSSH/wiki
$url = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.1.0.0p1-Beta/OpenSSH-Win64.zip"
$tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } –PassThru
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -OutFile $tmp $url
$tmpDir = [System.IO.Path]::GetTempPath()
$tmp | Expand-Archive -DestinationPath $tmpDir -Force
cd $tmpDir/OpenSSH-Win64
powershell.exe -ExecutionPolicy Bypass -File install-sshd.ps1
Set-Service sshd -StartupType Automatic
# It seems that the default configuration doesn't allow connection, however the sshd -d command works

