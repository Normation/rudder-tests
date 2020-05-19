require "spec_helper"
require "rudder"

reports = $params["REPORTS"].split("\n").map {|x| Rudder::Report.new(x)}.compact
# Test agent reports
describe agent_run do
  for report in reports
    its(:reports) { should include(report) }
  end
end
