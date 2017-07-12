require 'spec_helper'

nodes = $params['DELETE_NODES']
describe "Delete all"  do

  # delete rules
  describe command($rudderCli + " rules list | jq '.rules | .[].id' | xargs -n 1 " + $rudderCli + " rule delete ") do
    # To always make it succeed unless a command is missing
    # A better way would be to make the command ignore null
    its(:exit_status) { should_not eq 127 }
  end

  # delete directives
  describe command($rudderCli + " directive list | jq '.directives | .[].id' | xargs -n 1 " + $rudderCli + " directive delete ") do
    its(:exit_status) { should_not eq 127 }
  end

  if nodes == "yes" then
    # delete nodes
    describe command($rudderCli + " nodes list | jq '.nodes | .[0].id' | xargs -n 1 " + $rudderCli + " nodes delete ") do
      its(:exit_status) { should_not eq 127 }
    end
  end
  
end

