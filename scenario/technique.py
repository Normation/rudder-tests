#
# Techniques specific scenario that runs tests on one or more techniques
#
# Give it a directory parameter and it will test all techniques with a self test in it

from scenario.lib import *

# TODO: how do you rerun a test without killing the platform

# Get technique list from parameters
techniques = find_techniques()

# test begins, register start time
start()

# force inventory
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="-D force_inventory")
run_on("server", 'run_agent', Err.CONTINUE, PARAMS="")

# accept nodes
for host in scenario.nodes("agent"):
  run('localhost', 'agent_accept', Err.BREAK, ACCEPT=host)

# test all techniques
date0 = host_date('wait', Err.CONTINUE, "server")
for technique in techniques:
  # Add a technique/directive/rule
  run('localhost', 'techniques/technique_rule', Err.BREAK, TECHNIQUE=technique['name'], DIRECTIVE=technique['directive'], GROUP="special:all")

# Wait for generation
for host in scenario.nodes("agent"):
  wait_for_generation('wait', Err.CONTINUE, "server", date0, host, 20)

# Deploy all
run_on("server", 'run_agent', Err.CONTINUE, PARAMS="")
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="-f failsafe.cf")
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="")

# Test rule result
for technique in techniques:
  run_on("agent", technique['test'], Err.CONTINUE)

# TODO test rule compliance

# test end, print summary
finish()
