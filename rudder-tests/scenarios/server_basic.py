"""
Basic scenario for server test
"""
from lib.scenario import ScenarioInterface

class server_basic(ScenarioInterface):
  def __init__(self, name, datastate, scenario_input={}):
    schema = {}
    super().__init__(name, datastate, schema)
    self.input = scenario_input

  def execute(self):
    self.start()
    for server in self.nodes("server"):
      self.run_testinfra(server, "6_0_server")
      self.run_testinfra(server, "6_0_relay")
    for relay in self.nodes("relay"):
      self.run_testinfra(relay, "6_0_relay")
    self.finish()
