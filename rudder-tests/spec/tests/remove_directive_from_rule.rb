require "spec_helper"

directive_id = $params["DIRECTIVE_ID"]
rule_id = $params["RULE_ID"]

describe "Removing directive %s to rule %s" %[directive_id, rule_id] do

  # Get rule detail
  describe api_call("get", $rudderUrl + "/api/latest/rules/" + rule_id, $rudderToken, "") do
    its(:content_as_json) {should include("result" => "success")}
    its(:return_code) { should eq 200 }
    its(:data) {should include("rules")}
    $rule_detail = (described_class.data)["rules"][0]
  end

  $rule_detail["directives"] = $rule_detail["directives"] - [ directive_id ]

  describe api_call("post", $rudderUrl + "/api/latest/rules/" + rule_id, $rudderToken, $rule_detail) do
    its(:content_as_json) {should include("result" => "success")}
    its(:return_code) { should eq 200 }
    its(:data) {should include("rules")}
  end
end
