require 'spec_helper'
require 'json'

group = $params['GROUP']
directiveFiles = $params['DIRECTIVES']
index = $params['INDEX']
ruleFile = "/tmp/rule.json"
ruleName = $params['NAME']

describe "Add a directive and a rule"  do

  $directive_id ||= 1
  for directiveFile in directiveFiles.split(",") do
    file = File.read(directiveFile)
    data = JSON.parse(file)
    technique = data["techniqueName"]
    directiveName = data["displayName"] + " (" + index + "," + String($directive_id) + ")"
    $directive_id += 1
    # create directive
    describe command($rudderCli + " directive create --json=" + directiveFile + " " + technique + " '" + directiveName + "' | jq '.directives[0].id'") do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /^"[0-9a-f\-]+"$/ }
      it {
        # register output uuid for next command
        $directive_uuid ||= []
        puts subject.stdout
        puts subject.stdout.gsub(/^"|"$/, "").chomp()
        $directive_uuid.push(subject.stdout.gsub(/^"|"$/, "").chomp())
      }
    end
  end

  # create rule
  describe command($rudderCli + " rule create --json=" + ruleFile + " " + ruleName) do
    before(:all) {
      uuid_list = $directive_uuid.map { |u| '"'+u+'"' }
      uuids = uuid_list.join(",")
      File.open(ruleFile, 'w') { |file|
        file << <<EOF
{
  "directives": [
    #{uuids}
  ],
  "displayName": "#{ruleName}",
  "longDescription": "#{ruleName} Long Description",
  "shortDescription": "#{ruleName} Short Description",
  "enabled": true,
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
    #  File.delete(ruleFile)
    }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^"[0-9a-f\-]+"$/ }
  end

end
