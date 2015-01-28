require 'spec_helper'


describe command("/opt/rudder/bin/run-inventory --local=/tmp") do
  its(:exit_status) { should eq 0 }
end

# this is needed because before rudder 3.0 we couldn't specify the file name
describe command("mv $(ls -tr /tmp/*.ocs|tail -n1) /tmp/test.ocs") do
  its(:exit_status) { should eq 0 }
end

describe file("/tmp/test.ocs") do
   it { should contain('OSNAME').from(/<HARDWARE>/).to(/<.HARDWARE>/) }
   its(:content) { should match /<OSNAME>(?i:#{os[:family]}).*<.OSNAME>/ }
end
# >-rm -rf /tmp/x
# >-mkdir /tmp/x
# >-/opt/rudder/bin/run-inventory --local=/tmp/x
# >-sed -ne '/<HARDWARE>/,/<.HARDWARE>/p' /tmp/x/* | grep OSNAME | grep -i $TEST_SYSTEM
#
