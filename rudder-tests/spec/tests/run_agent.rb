require 'spec_helper'


describe command('/opt/rudder/bin/rudder agent ' + $params['PARAMS'] + ' -i') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should_not match /error:/ }
  its(:stderr) { should_not match /error:/ }
end

