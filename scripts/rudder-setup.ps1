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

param([Parameter(Mandatory)]$Version, $PolicyServer, $User, $Password)


function get_url($version0) {
  if($version0 -match '^ci/(.*)') {
    $version = $Matches[1]
    $urlBase = "https://publisher.normation.com"
  } else {
    $version = $version0
    $urlBase = "https://download.rudder.io"
  }
  if($version -match '^(.*)-nightly$') {
    $version = $Matches[1]
    $release = "nightly"
    $snapshot = "-SNAPSHOT"
  } else {
    $release = "release"
    $snapshot= ""
  }

  if($version -match '^(\d+\.\d+)-(\d+\.\d+)$') {
    $major = $Matches[1]
  } elseif($version -eq "latest") {
    $major = $version
  } else {
    throw "Error: version $version (from $version0) is invalid"
  }
  "$urlBase/plugins/$major/dsc/$release/rudder-agent-dsc-$version$snapshot.exe"
}


# download binary
$url = get_url($Version)
$tmpDir = [System.IO.Path]::GetTempPath()
$tmpFile = "$tmpDir\rudder-agent.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if([string]::IsNullOrEmpty($User)) {
  Invoke-WebRequest -OutFile $tmpFile -Uri $url
} else {
  $secpasswd = ConvertTo-SecureString $Password -AsPlainText -Force
  $credential = New-Object System.Management.Automation.PSCredential($User, $secpasswd)
  Invoke-WebRequest -OutFile $tmpFile -Credential $credential -Uri $url
}

# install
& "$tmpFile" /S /POLICYSERVER=$PolicyServer

# Remove fails because of a permission denied !?
#Remove-Item $tmpFile

