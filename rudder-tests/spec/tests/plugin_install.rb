require "spec_helper"

rpkg_path = $params["RPKG_PATH"]

# Check rudder-jetty status
describe service('rudder-jetty') do
  it { should be_running }
  it { should be_running.under('systemd') }
end
describe api_call("GET", $rudderUrl + "/api/latest/system/status", $rudderToken, {}) do
  its(:content_as_json) {should include("result" => "success")}
  its(:return_code) { should eq 200 }
  its(:data) {should include("global" => "OK")}
end

# Install plugin
describe command("rudder package install-file #{rpkg_path}") do
  its(:exit_status) { should eq 0 }
end

# Check rudder-jetty status post plugin install
describe service('rudder-jetty') do
  it { should be_running }
  it { should be_running.under('systemd') }
end
describe api_call("GET", $rudderUrl + "/api/latest/system/status", $rudderToken, {}) do
  its(:content_as_json) {should include("result" => "success")}
  its(:return_code) { should eq 200 }
  its(:data) {should include("global" => "OK")}
end
