require 'spec_helper'


describe file ('/opt/rudder/etc/rudder-networks.conf') do
    it { should be_file }
    its(:content) { should match /Allow from rudder/ }
end

