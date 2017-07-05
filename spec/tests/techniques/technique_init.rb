require 'spec_helper'

inits = $params['INITS']
initfile = "/tmp/init_technique"
version = $params['SERVER_VERSION']

describe "Initialise test"  do
  # run command
  #describe command("PATH=#{root}:$PATH /usr/local/bin/ncf -f /tmp/init_technique.cf") do
  for init in inits.split(",") do
    send_file(init, initfile)
    describe command("RUDDER_VERSION=#{version} #{initfile}") do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should_not match /error/i }
    end
  end
end
