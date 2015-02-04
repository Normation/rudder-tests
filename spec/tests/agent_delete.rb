require 'spec_helper'

acceptHost = params['DELETE']

describe "Delete node"  do

  # find node uuid
  describe command($rudderCli + " nodes list | jq '.nodes | map(select(.hostname==\"" + acceptHost + "\")) | .[0].id'") do
    its(:exit_status) { should eq 0 }
    it {
      # register output uuid for next command
      $uuid = subject.stdout.gsub(/^"|"$/, "").chomp()
    }
  end

  # delete uuid
  describe command($rudderCli + " nodes delete ") do
    # append uuid to command here because $uuid is not available within describe context
    it { subject.name << $uuid }
    its(:exit_status) { 
      should eq 0
    }
    its(:stdout) { should match /"id": "#{$uuid}"/ }
    its(:stdout) { should match /"hostname": "#{acceptHost}"/ }
    its(:stdout) { should match /"status": "deleted"/ }
  end

end
