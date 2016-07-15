"""
Scenario: technique
Parameters: test=<file1.metadata>,... a test file that describe the test to run, you can provide more than one test file by separating them with coma.

Techniques specific scenario that runs tests on one or more techniques.
Use it on the all_agents platform to test your technique on all available agents.
It will not clear the platform at the end of the test. Use the reset technique instead.
"""

from scenario.lib import *
import time

# Test begins, register start time
start(__doc__)

# Get test list from parameters
tests = get_tests()

# Force inventory
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="-D force_inventory")
run_on("server", 'run_agent', Err.CONTINUE, PARAMS="")

# Accept nodes
for host in scenario.nodes("agent"):
  run('localhost', 'agent_accept', Err.BREAK, ACCEPT=host)

# Run test init script
for test in tests:
  if 'init' in test:
    run_on("all", 'techniques/technique_init', Err.BREAK, INIT=test['init'])

# Test all techniques
date0 = host_date('wait', Err.CONTINUE, "server")
for test in tests:
  # Add a technique/directive/rule
  run('localhost', 'techniques/technique_rule', Err.BREAK, 
            TECHNIQUE=test['name'], 
            DIRECTIVE=test['directive'], 
            GROUP="special:all",
            NAME=test['directive_name'])

# Wait for generation
for host in scenario.nodes("agent"):
  wait_for_generation('wait', Err.CONTINUE, "server", date0, host, 20)

# Deploy all
run_on("server", 'run_agent', Err.CONTINUE, PARAMS="")
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="-f failsafe.cf")
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="")

# Test rule result
for test in tests:
  run_on("agent", test['check'], Err.CONTINUE)

# Test rule compliance
time.sleep(5) # wait for server to compute compliance
for test in tests:
  run('localhost', 'techniques/technique_compliance', Err.CONTINUE, RULE=test['directive_name'], COMPLIANCE=str(test['compliance']))

# test end, print summary
finish()
