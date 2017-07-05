require 'spec_helper'

describe file('/var/rudder/cfengine-community/bin/cf-agent') do
  it { should be_executable }
  it { should be_owned_by 'root' }
# serverspec bug -> disabled
#  it { should be_mode 700 }
end

describe file('/var/rudder/cfengine-community/policy_server.dat') do
  it { should be_file }
  its(:content) { should match /server|rudder|127.0.0.1/ }
end

describe command('getent hosts $(cat /var/rudder/cfengine-community/policy_server.dat)') do
  its(:exit_status) { should eq 0 }
end

#describe process("cf-execd") do
#  it { should be_running }
#end

