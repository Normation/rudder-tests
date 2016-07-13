require 'spec_helper'

rule = $params['RULE']
compliance = $params['COMPLIANCE']

describe "Check compliance"  do

  # get rule compliance
  describe command($rudderCli + " rule list | jq '.rules | map(select(.displayName==\"" + rule + "\")) | .[0].id'" +
                   " | tr -d '\"' | xargs -n1 " +
                   $rudderCli + " compliance rule | jq '.rules[].compliance'") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^#{compliance}$/ }
  end
end
