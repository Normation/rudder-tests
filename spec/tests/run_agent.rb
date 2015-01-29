require 'spec_helper'

params = ENV['RUDDER_PARAMS']

describe command('/var/rudder/cfengine-community/bin/cf-agent -KI ' + params) do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should_not match /error:/ }
end

