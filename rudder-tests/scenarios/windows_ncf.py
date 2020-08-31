"""
Run ncf tests on a given windows node
"""
from lib.scenario import ScenarioInterface

class windows_ncf(ScenarioInterface):
  def __init__(self, name, datastate, scenario_input={}):
    schema = {
      "node": { "schema": { "$ref": "#host"} , "min": 1},
    }
    super().__init__(name, datastate, schema)
    self.input = scenario_input

  def execute(self):
    self.start()
    agent = self.nodes("agent")[0]

    # retrieve ncf folder from git
    version = "6.1"
    branch = "branches/rudder/" + version
    self.ssh_on("localhost", "git clone --branch " + branch + " git@github.com:Normation/rudder-agent-windows.git " + self.workspace + "/rudder-agent-windows")
    # push it on the agent
    self.push_on(agent, self.workspace + "/rudder-agent-windows/packaging/tests", "C:\Program Files\Rudder", True)
    self.run_testinfra(agent, "windows_ncf")
    self.finish()
