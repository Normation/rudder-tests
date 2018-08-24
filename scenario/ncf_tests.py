"""
Scenario: ncf_test
Parameters: TAG=4.3 define the ncf branch we want to test on this environment.

"""

from scenario.lib import *
import time
from pprint import pprint

# Test begins, register start time
start(__doc__)

# Get TAG
tag = get_param("tag", "")
pprint("TAG => " + tag)

# Get setup_ncf
shell_on("agent", "wget -O /tmp/ncf-setup https://www.rudder-project.org/tools/ncf-setup", live_output=True)
# Call setup_ncf
shell_on("agent", "sh /tmp/ncf-setup test-local https://github.com/Normation/ncf.git#branches/rudder/" + tag + " rudder-latest", live_output=True)

finish()
