require 'spec_helper'

group = $params['GROUP']
technique = $params['TECHNIQUE']
directiveFile = $params['DIRECTIVE']
directiveName = technique + " test directive"
ruleFile = "/tmp/rule.json"
ruleName = technique + " test rule"

describe "Add a user directive and a rule"  do

  # create directive
  describe command($rudderCli + " directive create --json=" + directiveFile + " " + technique + " '" + directiveName + "'") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^"[0-9a-f\-]+"$/ }
    it {
      # register output uuid for next command
      $uuid = subject.stdout.gsub(/^"|"$/, "").chomp()
    }
  end

  # create rule
  describe command($rudderCli + " rule create --json=" + ruleFile + " " + ruleName) do
    before(:all) {
      File.open(ruleFile, 'w') { |file|
        file << <<EOF
{
  "directives": [
    "#{$uuid}"
  ],
  "displayName": "#{ruleName}",
  "longDescription": "#{ruleName} Long Description",
  "shortDescription": "#{ruleName} Short Description",
  "targets": [
    {
      "exclude": {
        "or": []
      },
      "include": {
        "or": [
          "#{group}"
        ]
      }
    }
  ]
}
EOF
      }
    }
    after(:all) {
      File.delete(ruleFile)
    }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^"[0-9a-f\-]+"$/ }
    it {
      # register output uuid for next command
      $uuid = subject.stdout.gsub(/^"|"$/, "").chomp()
    }
  end

end
