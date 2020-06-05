import json
import uuid
import os
from lib.scenario import ScenarioInterface, Err
from lib.rudder import Report
from lib.utils import replace_value

# Include local json file
package_directory = os.path.dirname(os.path.abspath(__file__))
directive_file = os.path.join(package_directory, "directive.json")

class test_user(ScenarioInterface):
  def __init__(self, name, datastate, scenario_input={}):
    schema = {
      "servers": { "schema": { "$ref": "#rudder_server"} , "min": 1, "max": 1},
      "agents" : { "schema": { "$ref": "#rudder_agent"}  , "min": 1 },
    }
    super().__init__(name, datastate, schema)
    self.input = scenario_input

  def execute(self):
      self.start()

      ## Compute values
      directive_id = self.input["directive_id"] if "directive_id" in self.input else str(uuid.uuid4())
      directive_name = self.input["directive_name"] if "directive_name" in self.input else "Test user Directive"

      rule_id = self.input["rule_id"] if "rule_id" in self.input else str(uuid.uuid4())
      rule_name = self.input["rule_name"] if "rule_name" in self.input else "Test user Rule"

      agent = self.nodes("agent")[0]
      server = self.nodes("server")[0]
      username = self.input["username"] if "username" in self.input else "Test_User"

      ## Create Directive
      with open(directive_file) as json_file:
        directive = json.load(json_file)
      replace_value(directive, "#{username}", self.input["username"])
      directive["displayName"] = directive_name
      directive["id"] = directive_id

      self.run("localhost", "directive_create", CONTENT=json.dumps(directive))

      # Save generation time
      date0 = self.host_date(server)

      ## Add a rule with the directive
      self.run('localhost', 'create_rule', DIRECTIVES=directive_id, RULE_ID=rule_id, TARGETS="special:all_exceptPolicyServers")

      ## Test execution
      self.wait_for_generation(server, date0, agent, 10)

      ## Run agent
      reports = [
              Report(ruleId=rule_id, directiveId=directive_id, component="Home directory", key=username, nodeId=self.get_uuid(agent)),
              Report(ruleId=rule_id, directiveId=directive_id, component="Password", key=username, nodeId=self.get_uuid(agent)),
              Report(ruleId=rule_id, directiveId=directive_id, component="Users", key=username, nodeId=self.get_uuid(agent))
      ]

      self.run(agent, 'run_command', COMMAND="rudder agent update")
      self.run(agent, 'report', REPORTS="\n".join(map(str, reports)))

      # Verify that the user exists on host
      self.run(agent, "user_test", USERNAME=username)

      # Delete directive and rule
      self.run("localhost", "directive_delete", UUID=directive_id)
      self.run("localhost", "rule_delete", UUID=rule_id)

      # test end, print summary
      self.finish()
