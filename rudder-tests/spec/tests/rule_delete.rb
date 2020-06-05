require 'spec_helper'

$rule_id = $params['UUID']

describe "Delete rule"  do
  describe api_call("DELETE", $rudderUrl + "/api/latest/rules/" + $rule_id, $rudderToken, "") do
    its(:content_as_json) {should include("result" => "success")}
    its(:return_code) { should eq 200 }
    its(:data) {should include("rules")}
  end
end
