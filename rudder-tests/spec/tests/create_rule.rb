require "spec_helper"

targets = $params["TARGETS"].split("\n") || [""]
rule_id = $params["RULE_ID"]
directives = $params["DIRECTIVES"].split("\n") || [""]

displayname = $params["DISPLAYNAME"] || "RTF generated rule"
short_description = $params["SHORT_DESCRIPTION"] || ""
long_description = $params["LONG_DESCRIPTION"] || ""
enabled = $params["ENABLED"] || true


describe "Creating rule %s with groups %s and directives %s" %[rule_id, targets, directives] do
  # Create rule detail
  $rule_detail = Hash.new("")
  $rule_detail["id"] = rule_id
  $rule_detail["targets"] = targets
  $rule_detail["directives"] = directives

  $rule_detail["displayName"] = displayname
  $rule_detail["shortDescription"] = short_description
  $rule_detail["longDescription"] = long_description
  $rule_detail["enabled"] = enabled
  $rule_detail["system"] = false
  $rule_detail["tags"] = []

  describe api_call("put", $rudderUrl + "/api/latest/rules", $rudderToken, $rule_detail) do
    its(:content_as_json) {should include("result" => "success")}
    its(:return_code) { should eq 200 }
    #its(:data) {should include("rules")}
  end
end
