"""
Scenario: create_user

Create a user directive with the given name and directive_id.
It will triggers the agents run to apply it.

"""
from scenario.lib import *

class Scenario():
  def __init__(self, data):
    self.data = data

  def run(self):
      # test begins, register start time
      start(__doc__)

      # Add a rule
      date0 = host_date('wait', Err.CONTINUE, "server")
      run('localhost', 'user_rule', Err.BREAK, NAME="Test User " + self.data['username'], GROUP="special:all", USERNAME=self.data['username'], DIRECTIVE_ID=self.data['directive_id'])
      for host in scenario.nodes("agent"):
        wait_for_generation('wait', Err.CONTINUE, "server", date0, host, 10)

      # Run agent
      run_on("server", 'run_agent', Err.CONTINUE, PARAMS="run")
      run_and_dump("agent", 'run_agent', Err.CONTINUE, RudderLog.APACHE, PARAMS="update")
      run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="run")

      # Test rule result
      run_on("agent", 'user_test', Err.CONTINUE, USERNAME=self.data['username'])

      # test end, print summary
      finish()
