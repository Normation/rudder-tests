require 'spec_helper'

name = $params['DELETE']

describe "Delete rule"  do

  # find rule uuid
  describe command($rudderCli + " rules list | jq '.rules | map(select(.displayName==\"" + name + "\")) | .[0].id'") do
    it {
      # register output uuid for next command
      $uuid = subject.stdout.gsub(/^"|"$/, "").chomp()
    }
    its(:exit_status) { should eq 0 }
  end

  # delete uuid
  describe command($rudderCli + " rule delete ") do
    # append uuid to command here because $uuid is not available within describe context
    it { subject.name << $uuid }
    its(:stdout) { should match /"id": "#{$uuid}"/ }
    its(:stdout) { should match /"displayName": "#{name}"/ }
    its(:exit_status) { 
      should eq 0
    }
  end

end
