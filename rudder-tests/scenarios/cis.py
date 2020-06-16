"""
Basic scenario for the cis plugin
"""
from lib.scenario import ScenarioInterface

class cis(ScenarioInterface):
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

    # Validate rpkg
    from scenarios import plugin_basic
    rpkg_scenario = plugin_basic("Test rpkg file", self.datastate, self.input)
    rpkg_scenario.execute()

    # Install dependencies
    self.run(server, "run_command", COMMAND="apt-get -y install rudder-api-client || yum install -y rudder-api-client || zypper --non-interactive in rudder-api-client")


    # Install rpkg
    from scenarios import plugin_install
    rpkg_install = plugin_install("Test rpkg installation", self.datastate, self.input)
    rpkg_install.execute()

    # Test plugin specific tests
    from scenarios import b078d18e_7a99_4bd5_8386_43eaf4f3669f
    dir1 = b078d18e_7a99_4bd5_8386_43eaf4f3669f("Test directive b078d18e_7a99_4bd5_8386_43eaf4f3669f", self.datastate, "")
    dir1.execute()

    self.finish()
