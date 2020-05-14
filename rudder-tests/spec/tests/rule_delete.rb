require 'spec_helper'

rule_id = $params['RULE_ID']

describe "Delete rule"  do
  describe api_call("delete", $rudderUrl + "/api/latest/rules/" + rule_id, $rudderToken, {}) do
    its(:content_as_json) {should include("result" => "success")}
    its(:return_code) { should eq 200 }
    its(:data) {should include("rules")}
  end
end
