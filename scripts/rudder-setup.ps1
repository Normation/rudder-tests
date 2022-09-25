<#
.SYNOPSIS
    Install Rudder agent for windows on given version.

.DESCRIPTION
    It can retreive the binary and install it using your credentials if provided.
    TODO: check sha512 sum and signature
    TODO: allow "latest" and "nightly" as a version
    TODO: add action setup/upgarde/remove

.PARAMETER Version
    Rudder version to install.
    Supported values:
        x.y-a.b             the version a.b of the agent build for rudder x.y
        x.y-a.b-nightly     the nightly version a.b of the agent build for rudder x.y
        ci/x.y-a.b          the version a.b of the agent build for rudder x.y from internal ci
        ci/x.y-a.b-nightly  the nightly version a.b of the agent build for rudder x.y from internal ci
.PARAMETER PolicyServer
    Policy-server to connect to.
.PARAMETER User
    User to connect to repository for private downloads.
.PARAMETER Password
    Password to connect to repository for private downloads.
#>

param(
  [Parameter(Mandatory)]
  $version,
  $policyServer,
  [Parameter(Mandatory)]
  $user,
  [Parameter(Mandatory)]
  $password
)

function Get-Url($version) {
  if($version -match '^ci/(.*)') {
    $version = $matches[1]
    $urlBase = "https://publisher.normation.com"
  } else {
    $version = $version
    $urlBase = "https://download.rudder.io"
  }
  if($version -match '^(.*)-nightly$') {
    $version = $matches[1]
    $release = "nightly"
    $snapshot = "-SNAPSHOT"
  } else {
    $release = "release"
    $snapshot= ""
  }

  $majorVersion = if($version -match '^(\d+\.\d+)-(\d+\.\d+)$') {
    # plugin version < 7.0
    $matches[1]
  } elseif($version -match '^(\d+\.\d+)(-.*)?$') {
    # plugin version >= 7.0
    $matches[1]
  } elseif($version -eq "latest") {
    $version
  } else {
    throw "Error: version ${version} (from ${version}) is invalid"
  }

  if ($majorVersion[0] -in @("5", "6")) {
    "${urlBase}/plugins/${majorVersion}/dsc/${release}/rudder-agent-dsc-${version}${snapshot}.exe"
  } else {
    "${urlBase}/misc/windows/${version}/latest"
  }
}


# download binary
$url = Get-Url($version)
Write-Host "Downloading '${url}'..."
$tmpDir = [System.IO.Path]::GetTempPath()
# tmpDir ends with a backslash already
$tmpFile = "${tmpDir}rudder-agent.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if([string]::IsNullOrEmpty($user)) {
  Invoke-WebRequest -OutFile $tmpFile -Uri $url
} else {
  $secPasswd = ConvertTo-SecureString $password -AsPlainText -Force
  $credential = New-Object System.Management.Automation.PSCredential($user, $secPasswd)
  Invoke-WebRequest -OutFile $tmpFile -Credential $credential -Uri $url
}

# install
Write-Host "Executing '& `"${tmpFile}`" /S /POLICYSERVER=`"${policyServer}`""
& "${tmpFile}" /S /POLICYSERVER="${policyServer}"

Write-Host "Waiting for install to finish..."
while (-not (Test-Path "C:\Program Files\Rudder\Uninstall.exe")) { Start-Sleep 1 }

# Remove fails because of a permission denied !?
Remove-Item $tmpFile -Force | Out-Null
