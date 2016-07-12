require 'spec_helper'

rule = $params['RULE']
compliance = $params['COMPLIANCE']

describe "Check compliance"  do

  # get rule compliance
  describe command($rudderCli + " compliance rule " + rule + " | jq '.rules[].compliance'") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^#{compliance}$/ }
  end
end
