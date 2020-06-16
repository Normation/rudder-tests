"""
Basic scenario for plugin testing
"""
from lib.scenario import ScenarioInterface

class plugin_basic(ScenarioInterface):
  def __init__(self, name, datastate, scenario_input={}):
    schema = {}
    super().__init__(name, datastate, schema)
    self.input = scenario_input

  def execute(self):
    self.start()
    plugin_path = self.input["plugin-path"]
    plugin_name = self.input["plugin-name"]
    plugin_version = self.input["plugin-version"]
    server = self.nodes("server")[0]

    self.run("localhost", 'plugin_basic', PLUGIN_PATH=plugin_path, PLUGIN_NAME=plugin_name, PLUGIN_VERSION=plugin_version)
    self.finish()
