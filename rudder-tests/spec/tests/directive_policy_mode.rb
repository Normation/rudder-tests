require "spec_helper"

directive_id = $params["DIRECTIVE_ID"]
policy_mode = $params["POLICY_MODE"]

describe "Set policy mode of directive %s to %s" %[directive_id, policy_mode] do

  # Get directive detail
  describe api_call("get", $rudderUrl + "/api/latest/directives/" + directive_id, $rudderToken, "") do
    its(:content_as_json) {should include("result" => "success")}
    its(:return_code) { should eq 200 }
    its(:data) {should include("directives")}
    $directive_detail = (described_class.data)["directives"][0]
  end

  $directive_detail["policyMode"] = policy_mode

  describe api_call("post", $rudderUrl + "/api/latest/directives/" + directive_id, $rudderToken, $directive_detail) do
    its(:content_as_json) {should include("result" => "success")}
    its(:return_code) { should eq 200 }
    its(:data) {should include("directives")}
  end
end
