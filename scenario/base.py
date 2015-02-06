from scenario.lib import *

# Generic tests
run('agent1', 'fusion', Err.CONTINUE, OSNAME="")
run('agent1', 'agent', Err.CONTINUE)
run('server', 'fusion', Err.CONTINUE, OSNAME="")
run('server', 'agent', Err.CONTINUE)

# force inventory
run('agent1', 'run_agent', Err.CONTINUE, PARAMS="-D force_inventory")
run('server', 'run_agent', Err.CONTINUE, PARAMS="")

# accept node
run('localhost', 'agent_accept', Err.BREAK, ACCEPT='agent1')

# Add a rule
date0 = server_date('wait', Err.CONTINUE)
run('localhost', 'user_rule', Err.BREAK, NAME="Test User", GROUP="special:all")
wait_for_generation('wait', Err.CONTINUE, date0, 'agent1', 20)

# Run agent
run('agent1', 'run_agent', Err.CONTINUE, PARAMS="-f failsafe.cf")
run('agent1', 'run_agent', Err.CONTINUE, PARAMS="")

# Test rule result
run('agent1', 'user_test', Err.CONTINUE)

# remove rule/directive
run('localhost', 'directive_delete', Err.FINALLY, DELETE="Test User Directive", GROUP="special:all")
run('localhost', 'rule_delete', Err.FINALLY, DELETE="Test User Rule", GROUP="special:all")

# remove agent
run('localhost', 'agent_delete', Err.FINALLY, DELETE="agent1")

# test end, print summary
finish()
