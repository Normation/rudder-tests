"""
Scenario: upgrade

Generic scenario that tries many tests on a platform with or without a relay.
This is the base scenario that should be run to test a release.
"""
from scenario.lib import *
import os

# test begins, register start time
start(__doc__)

import scenario.accept_nodes as accept_nodes

import scenario.create_user as create_user

class Scenario():
  def __init__(self, data):
    self.data = data

  def run(self):
    # Test base rudder and accept nodes
    accept = accept_nodes.Scenario(None)
    accept.run()

    create1 = create_user.Scenario({ "username" : "test_user1", "directive_id" : "3188d0c4-db97-4a8d-bb05-2e8061b991b8" })
    create1.run()

    ## Upgrade
    test_shell_on("server", '/usr/local/bin/rudder-setup upgrade-server ' + self.data['target_version'], error_mode=Err.CONTINUE, live_output=True)
    ## Update API token and re-test the webapp
    (rudder_url, token) = scenario.platform.api_connection_info()
    setenv(scenario.platform.client_path, rudder_url, token)

    create2 = create_user.Scenario({ "username" : "test_user2", "directive_id" : "3188d0c4-db97-4a8d-bb05-2e8061b991b9" })
    create2.run()

    # test end, print summary
    finish()
