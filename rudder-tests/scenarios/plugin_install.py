"""
Install scenario for plugin testing
"""
from lib.scenario import ScenarioInterface

class plugin_install(ScenarioInterface):
  def __init__(self, name, datastate, scenario_input={}):
    schema = {
      "servers": { "schema": { "$ref": "#rudder_server"} , "min": 1, "max": 1},
    }
    super().__init__(name, datastate, schema)
    self.input = scenario_input

  def execute(self):
    self.start()
    plugin_path = self.input["plugin-path"]
    server = self.nodes("server")[0]

    dst = "/tmp/target_plugin.rpkg"
    self.push_on(server, plugin_path, dst)
    self.run_testinfra(server, 'plugin_install', PLUGIN_PATH=dst)
    self.finish()
