"""
Scenario: accept_nodes
Run inventory and accept all agents of the platform
"""
from scenario.lib import *

class Scenario():
  def __init__(self, data):
      self.data = data
  def run(self):
      # test begins, register start time
      start(__doc__)

      # Run inventory and accept nodes
      for host in scenario.nodes("agent"):
        run_on(host, 'run_agent', Err.CONTINUE, PARAMS="inventory")
        run_retry_and_dump('localhost', 'agent_accept', 5, RudderLog.APACHE, ACCEPT=host)

      finish()
