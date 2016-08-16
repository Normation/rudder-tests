require 'spec_helper'

init = $params['INIT']
send_file(init, "/tmp/init_technique.cf")

describe "Initialise test"  do
  # run command
  describe command("/usr/local/bin/ncf -f /tmp/init_technique.cf") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should_not match /error/i }
  end
end
