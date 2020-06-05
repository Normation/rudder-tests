"""

"""
from lib.scenario import ScenarioInterface

class inventory(ScenarioInterface):
  def __init__(self, name, datastate, scenario_input={}):
    schema = {
      "node": { "schema": { "$ref": "#host"} , "min": 1},
    }
    super().__init__(name, datastate, schema)
    self.username = "user_test"
    self.input = scenario_input

  def execute(self):
    self.start()
    for hostname, hostinfos in self.datastate.items():
      osname = hostinfos["inventory-os"] if "inventory-os" in hostinfos else ""

      self.run(hostname, 'fusion', OSNAME=osname)

    self.finish()
