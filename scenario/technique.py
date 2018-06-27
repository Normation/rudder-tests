"""
Scenario: technique
Parameters: test=<file1.metadata>,... a test file that describe the test to run, you can provide more than one test file by separating them with coma.

Techniques specific scenario that runs tests on one or more techniques.
Use it on the all_agents platform to test your technique on all available agents.
It will not clear the platform at the end of the test. Use the reset technique instead.
"""

from scenario.lib import *
import time
from pprint import pprint

# Test begins, register start time
start(__doc__)

# Get test list from parameters
tests = get_tests()

# Force inventory
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="inventory")
run_on("server", 'run_agent', Err.CONTINUE, PARAMS="run")

if scenario.startTestNumber == 0:
# Accept nodes
  for host in scenario.nodes("agent"):
    run('localhost', 'agent_accept', Err.BREAK, ACCEPT=host)

# Run all tests
test_id=1
for test in tests:
  # define rule name
  if 'name' in test:
    rule_name=test['name']
  else:
    rule_name="test_"+str(test_id)

  # Run init script
  if 'inits' in test:
    for iInit in test['inits']:
        run_on("agent", 'techniques/technique_init', Err.BREAK, INIT=iInit, SERVER_VERSION=scenario.server_rudder_version())

  # Add the shared-Files on the server
  if 'sharedFiles' in test:
    for iFile in test['sharedFiles']:
        run_on("server", 'techniques/technique_sharedFiles', Err.BREAK, FILE=iFile)
  date0 = host_date('wait', Err.CONTINUE, "server")
  # delete directive/rule with given names
  run('localhost', 'techniques/technique_clean', Err.BREAK, 
            DIRECTIVES=",".join(test['directives']),
            INDEX=str(test_id),
            GROUP="special:all_exceptPolicyServers",
            NAME=rule_name)
  # Add a technique/directive/rule
  run('localhost', 'techniques/technique_rule', Err.BREAK, 
            DIRECTIVES=",".join(test['directives']),
            INDEX=str(test_id),
            GROUP="special:all_exceptPolicyServers",
            NAME=rule_name)

  # Wait for generation
  for host in scenario.nodes("agent"):
    wait_for_generation('wait', Err.CONTINUE, "server", date0, host, 20)

  # Deploy
  run_on("server", 'run_agent', Err.CONTINUE, PARAMS="run")
  run_on("relay", 'run_agent', Err.CONTINUE, PARAMS="update") # could be replaced by run -u after 4.0
  run_on("relay", 'run_agent', Err.CONTINUE, PARAMS="run")
  run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="update")
  run_on("agent", 'technique_run_agent', Err.CONTINUE, PARAMS="run", NAME="test_output.log")

  # Test rule result
  for check in test['checks']:
    run_test_on(test_id, "agent", check, Err.CONTINUE)

  # Test rule compliance
  time.sleep(10) # wait for server to compute compliance
  run('localhost', 'techniques/technique_compliance', Err.CONTINUE, RULE=rule_name, COMPLIANCE=str(test['compliance']))
  test_id+=1

# test end, print summary
finish()
