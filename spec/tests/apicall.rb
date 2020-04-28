require 'spec_helper'

describe api_call('get', $rudderUrl + "/api/latest/nodes", $rudderToken, "") do
  its(:content_as_json) {should include('result' => 'success')}
  its(:return_code) { should eq "200" }
  its(:data) {should include("nodes")}
end
