"""
Install scenario for plugin testing
"""
from lib.scenario import ScenarioInterface

class plugin_install(ScenarioInterface):
  def __init__(self, name, datastate, scenario_input={}):
    schema = {}
    super().__init__(name, datastate, schema)
    self.input = scenario_input

  def execute(self):
    self.start()
    plugin_path = self.input["plugin-path"]
    server = self.nodes("server")[0]

    dst = "/tmp/target_plugin.rpkg"
    self.push_on(server, plugin_path, dst)
    self.run(server, 'plugin_install', RPKG_PATH=dst)
    self.finish()
