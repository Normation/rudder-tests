BeforeAll {
  . $PSScriptRoot/rudder-setup.ps1
}

Describe 'Get-Url' {
  It 'Should parse the given content' -ForEach @(
    @{
      version = '7.2'
      expectedUrl = 'https://download.rudder.io/misc/windows/7.2/latest'
    },
    @{
      version = '7.2-nightly'
      expectedUrl = 'https://download.rudder.io/misc/windows/7.2-nightly/latest'
    },
    @{
      version = '7.2.1'
      expectedUrl = 'https://download.rudder.io/misc/windows/7.2.1/latest'
    },
    @{
      version = 'ci/7.2.1'
      expectedUrl = 'https://publisher.normation.com/misc/windows/7.2.1/latest'
    },
    @{
      version = '6.2-1.24'
      expectedUrl = 'https://download.rudder.io/plugins/6.2/dsc/release/rudder-agent-dsc-6.2-1.24.exe'
    },
    @{
      version = 'ci/6.2-1.24'
      expectedUrl = 'https://publisher.normation.com/plugins/6.2/dsc/release/rudder-agent-dsc-6.2-1.24.exe'
    }
    @{
      version = '5.0-1.16-nightly'
      expectedUrl = 'https://download.rudder.io/plugins/5.0/dsc/nightly/rudder-agent-dsc-5.0-1.16-SNAPSHOT.exe'
    },
    @{
      version = 'ci/5.0-1.16-nightly'
      expectedUrl = 'https://publisher.normation.com/plugins/5.0/dsc/nightly/rudder-agent-dsc-5.0-1.16-SNAPSHOT.exe'
    }
  ) {
    Get-Url $version | Should -Be $expectedUrl
  }
}

