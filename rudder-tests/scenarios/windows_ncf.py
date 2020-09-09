"""
Run ncf tests on a given windows node
If the scenario_input contains a test_files array, only the files
present in the array will be tested. The paths need to be absolute and
based from their location on the target machine.

Otherwise, it will run all the tests located in the folder:
    C:\Program Files\Rudder\tests

Ex:
    {
      "test_files": [ "C:/Program Files/Rudder/tests/Command_Execution.Tests.ps1",
                      "C:/Program Files/Rudder/tests/Condition_from_variable_match.Tests.ps1"
                    ]
    }
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

    # execute the expected tests
    if "test_files" in self.input:
      for f in self.input["test_files"]:
        self.run_testinfra(agent, "windows_ncf", TEST_PATH=f)
    else:
        self.run_testinfra(agent, "windows_ncf", TEST_PATH="all")

    self.finish()
