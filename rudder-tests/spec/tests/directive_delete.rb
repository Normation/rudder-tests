require 'spec_helper'

name = $params['DELETE']

describe "Delete node"  do

  # find directive uuid
  describe command($rudderCli + " directive list | jq '.directives | map(select(.displayName==\"" + name + "\")) | .[0].id'") do
    its(:exit_status) { should eq 0 }
    it {
      # register output uuid for next command
      $uuid = subject.stdout.gsub(/^"|"$/, "").chomp()
    }
  end

  # delete uuid
  describe command($rudderCli + " directive delete ") do
    # append uuid to command here because $uuid is not available within describe context
    it { subject.name << $uuid }
    its(:stdout) { should match /"id": "#{$uuid}"/ }
    its(:stdout) { should match /"displayName": "#{name}"/ }
    its(:exit_status) { 
      should eq 0
    }
  end

end
