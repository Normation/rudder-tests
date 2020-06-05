require "spec_helper"
require 'json'

# Content must be a json string
$content = JSON.parse($params["CONTENT"])

describe "Create a new directive" do

  describe api_call("put", $rudderUrl + "/api/latest/directives", $rudderToken, $content) do
    its(:content_as_json) {should include("result" => "success")}
    its(:return_code) { should eq 200 }
    its(:data) {should include("directives")}
  end
end
