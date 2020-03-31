"""
Scenario: base

Generic scenario that tries many tests on a platform with or without a relay.
This is the base scenario that should be run to test a release.
"""
import uuid
from scenario.lib import *

# test begins, register start time
start(__doc__)
username = "user_test"
directive_id = str(uuid.uuid4())

# Generic tests
for host in scenario.nodes():
  hostinfo = scenario.platform.hosts[host].info
  osname = hostinfo['inventory-os'] if 'inventory-os' in hostinfo else ""
  run(host, 'fusion', Err.CONTINUE, OSNAME=osname)

run_on("all", 'agent', Err.CONTINUE)

# force inventory
run_on("relay", 'run_agent', Err.CONTINUE, PARAMS="update")
run_on("relay", 'run_agent', Err.CONTINUE, PARAMS="run")
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="inventory")
run_on("relay", 'run_agent', Err.CONTINUE, PARAMS="run")
run_on("server", 'run_agent', Err.CONTINUE, PARAMS="run")

# accept nodes
for host in scenario.nodes("agent"):
  run_retry_and_dump('localhost', 'agent_accept', 5, RudderLog.APACHE, ACCEPT=host)

# Add a rule
date0 = host_date('wait', Err.CONTINUE, "server")
run('localhost', 'user_rule', Err.BREAK, NAME="Test User", GROUP="special:all", USERNAME=username, DIRECTIVE_ID=directive_id )
for host in scenario.nodes("agent"):
  wait_for_generation('wait', Err.CONTINUE, "server", date0, host, 20)

# Run agent
run_on("server", 'run_agent', Err.CONTINUE, PARAMS="run")
run_and_dump("relay", 'run_agent', Err.CONTINUE, RudderLog.APACHE, PARAMS="update")
run_on("relay", 'run_agent', Err.CONTINUE, PARAMS="run")
run_and_dump("agent", 'run_agent', Err.CONTINUE, RudderLog.APACHE, PARAMS="update")
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="run")

# Test rule result
run_on("agent", "user_test", Err.CONTINUE, USERNAME=username)

# remove rule/directive
run('localhost', 'directive_delete', Err.FINALLY, DELETE="Test User Directive")
run('localhost', 'rule_delete', Err.FINALLY, DELETE="Test User Rule")

# remove agent
for host in scenario.nodes("agent"):
  run('localhost', 'agent_delete', Err.FINALLY, DELETE=host)

# test end, print summary
finish()
