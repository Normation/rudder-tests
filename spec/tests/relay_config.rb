require 'spec_helper'

ipRange = $params['IPRANGE']

describe file ('/opt/rudder/etc/rudder-networks.conf') do
    it { should be_file }
    its(:content) { should match /Allow from #{ipRange}/ }
end

