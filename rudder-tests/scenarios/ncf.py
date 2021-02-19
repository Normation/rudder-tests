"""
 Trigger the ncf tests on a given agent

Ex:
    {
      "version": "6.1"
    }

    or

    {
      "version": "6.1"
      "pull_number": "276k"
    }
"""
from lib.scenario import ScenarioInterface

class ncf(ScenarioInterface):
  def __init__(self, name, datastate, scenario_input={}):
    schema = {
      "node": { "schema": { "$ref": "#host"} , "min": 1},
    }
    super().__init__(name, datastate, schema)
    self.input = scenario_input

  def execute(self):
    self.start()
    agent = self.nodes("empty")[0]
    remote_dst = "/tmp/ncf-setup"

    # Upload ncf-setup to the target node
    local_dst = self.workspace + "/ncf-setup"
    self.ssh_on("localhost", "wget -O " + local_dst + " https://repository.rudder.io/tools/ncf-setup")
    self.push_on(agent, local_dst, remote_dst)
    self.ssh_on(agent, "chmod +x " + remote_dst)

    # Run the ncf_test
    self.run_testinfra(agent, 'ncf', VERSION=self.input['version'])
    self.ssh_on(agent, "cat /tmp/ncf_tests.log", live_output=True)

    self.finish()
