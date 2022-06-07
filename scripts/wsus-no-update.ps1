param($server)
$wuRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
New-Item -Path $wuRegPath -Name AU -Force

#Remove uneeded entries
$whiteList = "(Default)","NoAutoUpdate","UseWUServer","AutoInstallMinorUpdates"
$toRemove = (Get-ChildItem -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate').Property | Where { $_ -notin $whiteList }
$toRemove | Foreach-Object { Remove-ItemProperty -Path "${wuRegPath}/AU" -Name $_ }

$reg = @(
 @{ Path = $wuRegPath; Key = "AllowAutoWindowsUpdateDownloadOverMeteredNetwork"; Value = "0"; Type = "DWORD" },
 @{ Path = $wuRegPath; Key = "DoNotEnforceEnterpriseTLSCertPinningForUpdateDetection"; Value = "1"; Type = "DWORD" },
 @{ Path = $wuRegPath; Key = "FillEmptyContentUrls"; Value = "1"; Type = "DWORD" },
 @{ Path = $wuRegPath; Key = "SetProxyBehaviorForUpdateDetection"; Value = "0"; Type = "DWORD" },
 @{ Path = $wuRegPath; Key = "UpdateServiceUrlAlternate"; Value = ""; Type = "String" },
 @{ Path = $wuRegPath; Key = "WUServer"; Value = "http://${server}:8530"; Type = "String" },
 @{ Path = $wuRegPath; Key = "WUStatusServer"; Value = "http://${server}:8531"; Type = "String" },

 @{ Path = "${wuRegPath}/AU"; Key = "NoAutoUpdate"; Value = "1"; Type = "DWORD" },
 @{ Path = "${wuRegPath}/AU"; Key = "UseWUServer"; Value = "1"; Type = "DWORD" },
 @{ Path = "${wuRegPath}/AU"; Key = "AutoInstallMinorUpdates"; Value = "0"; Type = "DWORD" }
)

foreach ($item in $reg) {
  Set-ItemProperty -Path $item.Path -Name $item.Key -Value $item.Value -Type $item.Type
}

# Remove firewall for test instances
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
