"""
Scenario: base

Generic scenario that tries many tests on a platform with or without a relay.
This is the base scenario that should be run to test a release.
"""
import uuid
from .lib import ScenarioInterface, Err

class Scenario(ScenarioInterface):
  def __init__(self, name, datastate):
    super().__init__(name, datastate)
    self.username = "user_test"
    self.directive_id = str(uuid.uuid4())

  def execute(self):
    self.start()

    # Generic tests
    for host in self.datastate.keys():
      self.run(host, 'fusion', OSNAME="SUSE")

    # test end, print summary
    self.finish()
