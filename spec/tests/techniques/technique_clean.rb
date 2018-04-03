require 'spec_helper'
require 'json'

group = $params['GROUP']
directiveFiles = $params['DIRECTIVES']
index = $params['INDEX']
ruleFile = "/tmp/rule.json"
ruleName = $params['NAME']

describe "Cleaning directives" do
  for directiveFile in directiveFiles.split(",") do
    file = File.read(directiveFile)
    data = JSON.parse(file)
    directiveName = data["displayName"]

    # check if a directive with the same name already exist
    lookForDirective = $rudderCli + " directive list | jq -r '.directives[] | select(.displayName==\"#{directiveName}\") | .id'"
    puts "Executing: #{lookForDirective}"
    existingDirectiveId = `#{lookForDirective}`

    # delete directive with the same name
    deleteDirective = $rudderCli + " directive delete #{existingDirectiveId}"
    puts "Executing: #{deleteDirective}"
    result = `#{deleteDirective} 2>/dev/null`
  end
end

describe "Cleaning rules" do
  # check if a rule with the same name already exist
  lookForRule = $rudderCli + " rule list | jq -r '.rules[] | select(.displayName==\"#{ruleName}\") | .id'"
  puts "Executing: #{lookForRule}"
  existingRuleId = `#{lookForRule}`
  deleteRule = $rudderCli + " rule delete #{existingRuleId}"
  puts "Executing: #{deleteRule}"
  result = `#{deleteRule} 2>/dev/null`
end

