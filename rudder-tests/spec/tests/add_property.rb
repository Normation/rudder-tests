require "spec_helper"

node_id = $params["NODE_ID"]
property_type = $params["PROPERTY_TYPE"]
property_name = $params["PROPERTY_NAME"]
property_value = $params["PROPERTY_VALUE"]

describe "Set value of %s type property %s on node %s" %[property_type, property_name, node_id] do

  # Get node details
  describe api_call("get", $rudderUrl + "/api/latest/nodes/" + node_id, $rudderToken, "") do
    its(:content_as_json) {should include("result" => "success")}
    its(:return_code) { should eq 200 }
    its(:data) {should include("nodes")}
    $directive_detail = (described_class.data)["nodes"][0]
  end

  # String case
  if property_type == "string"
    $directive_detail["properties"][property_name] = property_value
  # json case
  elsif property_type == "json"
    $directive_detail["properties"][property_name] = property_value.to_
  else
  end
  $directive_detail["properties"][property_name] = property_value

  describe api_call("post", $rudderUrl + "/api/latest/directives/" + directive_id, $rudderToken, $directive_detail) do
    its(:content_as_json) {should include("result" => "success")}
    its(:return_code) { should eq 200 }
    its(:data) {should include("directives")}
  end
end
