from scenario.lib import *

# test begins, register start time
start()

# Generic tests
for host in scenario.all_nodes():
  hostinfo = scenario.platform.hosts[host].info
  osname = hostinfo['osname'] if 'osname' in hostinfo else ""
  run(host, 'fusion', Err.CONTINUE, OSNAME=osname)

run_on_all('agent', Err.CONTINUE)

# force inventory
run_on_agents('run_agent', Err.CONTINUE, PARAMS="-D force_inventory")
run_on_servers('run_agent', Err.CONTINUE, PARAMS="")

# accept nodes
for host in scenario.agent_nodes():
  run('localhost', 'agent_accept', Err.BREAK, ACCEPT=host)

# Add a rule
date0 = host_date('wait', Err.CONTINUE, "server")
run('localhost', 'user_rule', Err.BREAK, NAME="Test User", GROUP="special:all")
for host in scenario.agent_nodes():
  wait_for_generation('wait', Err.CONTINUE, "server", date0, host, 20)

# Run agent
run_on_agents('run_agent', Err.CONTINUE, PARAMS="-f failsafe.cf")
run_on_agents('run_agent', Err.CONTINUE, PARAMS="")

# Test rule result
run_on_agents('user_test', Err.CONTINUE)

# remove rule/directive
run('localhost', 'directive_delete', Err.FINALLY, DELETE="Test User Directive", GROUP="special:all")
run('localhost', 'rule_delete', Err.FINALLY, DELETE="Test User Rule", GROUP="special:all")

# remove agent
for host in scenario.agent_nodes():
  run('localhost', 'agent_delete', Err.FINALLY, DELETE=host)

# test end, print summary
finish()
