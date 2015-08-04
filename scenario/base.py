from scenario.lib import *

# test begins, register start time
start()

# Generic tests
for host in scenario.nodes():
  hostinfo = scenario.platform.hosts[host].info
  osname = hostinfo['inventory-os'] if 'inventory-os' in hostinfo else ""
  run(host, 'fusion', Err.CONTINUE, OSNAME=osname)

run_on("all", 'agent', Err.CONTINUE)

# force inventory
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="-D force_inventory")
run_on("server", 'run_agent', Err.CONTINUE, PARAMS="")

# accept nodes
for host in scenario.nodes("agent"):
  run('localhost', 'agent_accept', Err.BREAK, ACCEPT=host)

# Add a rule
date0 = host_date('wait', Err.CONTINUE, "server")
run('localhost', 'user_rule', Err.BREAK, NAME="Test User", GROUP="special:all")
for host in scenario.nodes("agent"):
  wait_for_generation('wait', Err.CONTINUE, "server", date0, host, 20)

# Run agent
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="-f failsafe.cf")
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="")

# Test relay configuration
run_on("relay", 'relay_config', Err.CONTINUE)

# Test rule result
run_on("agent", 'user_test', Err.CONTINUE)

# remove rule/directive
run('localhost', 'directive_delete', Err.FINALLY, DELETE="Test User Directive", GROUP="special:all")
run('localhost', 'rule_delete', Err.FINALLY, DELETE="Test User Rule", GROUP="special:all")

# remove agent
for host in scenario.nodes("agent"):
  run('localhost', 'agent_delete', Err.FINALLY, DELETE=host)

# test end, print summary
finish()
