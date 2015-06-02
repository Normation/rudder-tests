require 'spec_helper'


describe command('/var/rudder/cfengine-community/bin/cf-agent -KI ' + $params['PARAMS'] + ' | grep -v "error: Warning promised, need to create file"') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should_not match /error:/ }
end

