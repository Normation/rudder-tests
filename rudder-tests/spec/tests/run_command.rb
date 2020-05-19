require "spec_helper"

exit_status = $params["EXIT_STATUS"] || "0"
command = $params["COMMAND"]
describe command("#{command}") do
  its(:exit_status) { should eq exit_status.to_i }
end
