Write-Host "Setting FR keyboard"
Set-WinUserLanguageList -LanguageList fr-FR -Confirm:$false -Force

Write-Host "Install chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install Pester -y
choco install vim -y
