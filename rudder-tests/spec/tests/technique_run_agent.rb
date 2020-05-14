require 'spec_helper'

describe command('/opt/rudder/bin/rudder agent ' + $params['PARAMS'] + ' -ri > /tmp/' + $params['NAME']) do
  its(:exit_status) { should eq 0 }
end

