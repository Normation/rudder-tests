require 'spec_helper'

init = $params['INIT']
initfile = "/tmp/init_technique"
version = $params['SERVER_VERSION']

describe "Initialise test"  do
  # run command
  #describe command("PATH=#{root}:$PATH /usr/local/bin/ncf -f /tmp/init_technique.cf") do
    send_file(init, initfile)
    describe command("RUDDER_VERSION=#{version} #{initfile}") do
      its(:stdout) { should_not match /error/i }
      its(:exit_status) { should eq 0 }
    end
end
