require 'spec_helper'

osname = $params['OSNAME']

if osname.downcase().include? "red hat"
  fullname = "redhat"
else
  fullname = osname
end

version = {
  "debian" => "[0-9]+(.[0-9]+)*",
  "ubuntu" => "[0-9]+\.[0-9]+(.[0-9]+)*",
  "redhat" => "[0-9]+\.[0-9]+(.[0-9]+)*",
  "centos" => "[0-9]+\.[0-9]+(.[0-9]+)*",
  "suse"   => "[0-9]+",
}

describe command("/opt/rudder/bin/run-inventory --local=/tmp") do
  its(:exit_status) { should eq 0 }
end

# this is needed because before rudder 3.0 we couldn't specify the file name
describe command("mv $(ls -tr /tmp/*.ocs|tail -n1) /tmp/test.ocs") do
  its(:exit_status) { should eq 0 }
end

describe command("sed -ne '/<HARDWARE>/,/<.HARDWARE>/p' /tmp/test.ocs") do
   its(:stdout) { should match /<OSNAME>(?i:#{osname}).*<.OSNAME>/ }
end

describe command("sed -ne '/<OPERATINGSYSTEM>/,/<.OPERATINGSYSTEM>/p' /tmp/test.ocs") do
   its(:stdout) { should match /<NAME>(?i:#{osname}).*<.NAME>/ }
   its(:stdout) { should match /<FULL_NAME>(?i:#{fullname}).*<.FULL_NAME>/ }
   its(:stdout) { should match /<VERSION>(?i:#{version[osname.downcase()]})<.VERSION>/ }
end
# >-rm -rf /tmp/x
# >-mkdir /tmp/x
# >-/opt/rudder/bin/run-inventory --local=/tmp/x
# >-sed -ne '/<HARDWARE>/,/<.HARDWARE>/p' /tmp/x/* | grep OSNAME | grep -i $TEST_SYSTEM
#
