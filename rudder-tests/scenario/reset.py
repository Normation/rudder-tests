"""
Scenario: reset
Parameters: nodes=[yes|no] "no" disables accepted node removal.

Generic scenario that resets the platform.
It removes all rules, directives and accepted nodes.
It may not be useful as a standalone test but can be used after another scenario to rerun the tests.
"""

from scenario.lib import *
class Scenario():
  def __init__(self, data):
    self.data = data

  def run(self):
    # test begins, register start time
    start(__doc__)

    # remove everything
    delete = get_param("nodes", "yes")
    for host in scenario.nodes("agent"):
      run('localhost', 'delete_all', Err.FINALLY, DELETE_NODES=delete)

    # test end, print summary
    finish()
