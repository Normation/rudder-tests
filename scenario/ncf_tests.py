"""
Scenario: ncf_test
Parameters: TAG=4.3 define the ncf branch we want to test on this environment.

"""

from scenario.lib import *
import os
import time
from pprint import pprint

# Test begins, register start time
start(__doc__)

# Get TAG
tag = get_param("tag", "")
# Get CFEngine version used for the tests
cfengine_version = get_param("cfengine_version", "")
export_prefix = ""
try:
  download_user = os.environ['DOWNLOAD_USER']
  download_password = os.environ['DOWNLOAD_PASSWORD']

  if (download_user):
    export_prefix = "export DOWNLOAD_USER=" + download_user + " DOWNLOAD_PASSWORD=" + download_password
except:
  export_prefix = ""

# Get setup_ncf
shell_on("agent", "wget -O /tmp/ncf-setup https://repository.rudder.io/tools/ncf-setup", live_output=True)
# Call setup_ncf
if not cfengine_version:
  shell_on("agent", export_prefix + ";sh /tmp/ncf-setup test-local https://github.com/Normation/ncf.git#branches/rudder/" + tag + " rudder-" + tag + " --testinfra", live_output=True)
else:
  shell_on("agent", export_prefix + ";sh /tmp/ncf-setup test-local --testinfra https://github.com/Normation/ncf.git#branches/rudder/" + tag + " " + cfengine_version + " --testinfra", live_output=True)

finish()
