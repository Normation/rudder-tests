#
# Generic scenario that tries many tests on a server->relay->agent platform
#

from scenario.lib import *

# test begins, register start time
start()

# remove everything
delete = get_param("nodes", "yes")
for host in scenario.nodes("agent"):
  run('localhost', 'delete_all', Err.FINALLY, DELETE_NODES=delete)

# test end, print summary
finish()
