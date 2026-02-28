param(
    [Parameter(Mandatory=$true)]
    [string]$ExpectedIP,

    [int]$PrefixLength = 24
)

function Test-IPAssigned {
    param([string]$IP)
    $assignedIPs = Get-NetIPAddress -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress
    return $assignedIPs -contains $IP
}

$interfaces = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

$targetInterface = $null
foreach ($iface in $interfaces) {
    $ips = Get-NetIPAddress -InterfaceIndex $iface.ifIndex -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress
    if ($ips -eq $null -or ($ips | Where-Object { $_ -like "169.254.*" })) {
        $targetInterface = $iface
        break
    }
}

if ($null -eq $targetInterface) {
    Write-Host "Impossible de trouver l'interface à configurer"
    exit 1
}

Write-Host "Interface ciblée : $($targetInterface.Name)"

if (Test-IPAssigned $ExpectedIP) {
    Write-Host "L'IP $ExpectedIP est déjà assignée. Rien à faire."
    exit 0
}

Get-NetIPAddress -InterfaceIndex $targetInterface.ifIndex -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

New-NetIPAddress -InterfaceIndex $targetInterface.ifIndex -IPAddress $ExpectedIP -PrefixLength $PrefixLength

Write-Host "IP $ExpectedIP assignée à l'interface $($targetInterface.Name) avec masque $PrefixLength"

Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 8.8.8.8,8.8.4.4
