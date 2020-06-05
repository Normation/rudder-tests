require "spec_helper"

$UUID = $params["UUID"]

describe "Remove a directive" do

  describe api_call("DELETE", $rudderUrl + "/api/latest/directives/" + $UUID, $rudderToken, "") do
    its(:content_as_json) {should include("result" => "success")}
    its(:return_code) { should eq 200 }
    its(:data) {should include("directives")}
  end
end
