"""
Scenario: ncf_test
Parameters: TAG=4.3 define the ncf branch we want to test on this environment.
            If can also support redmine issue number

"""

from scenario.lib import *
import os
import time
import re
from pprint import pprint

class Scenario():
  def __init__(self, data):
    self.data = data

  def run(self):
    # Test begins, register start time
    start(__doc__)
    need_external_setup = ["ubuntu10_04", "ubuntu12_04", "ubuntu12_10", "ubuntu13_04", "sles11"]

    def external_setup():
      tag = get_param("tag", "")
      vagrant_shared = scenario.platform.hosts['agent'].info['sync_file'] if 'sync_file' in scenario.platform.hosts['agent'].info else '/vagrant'
      test_shell_on("localhost", "$(pwd)/scripts/external_setup_host " + scenario.pf + " " + tag, live_output=True)
      test_shell_on("agent", "mv " + vagrant_shared + "/external_files/" + scenario.pf + "/* /tmp/", live_output=True)
      shell_on("agent", "rpm --import /tmp/rudder_rpm_key.pub", live_output=True)
      shell_on("agent", "apt-key add /tmp/rudder_apt_key.pub", live_output=True)
      return "/tmp/ncf"

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
    if scenario.platform.hosts ['agent'].info['system'] in need_external_setup:
      ncf_version = external_setup()
    else:
      test_shell_on("agent", "wget -O /tmp/ncf-setup https://repository.rudder.io/tools/ncf-setup", live_output=True)

    # Get TAG
    tag = get_param("tag", "")
    # Testing a pull request
    if re.match(r"^[0-9]+$", tag):
      issue = extract_redmine_issue_infos(tag)
      m = re.match(".*/(?P<pull_id>[0-9]+)", get_issue_pr(issue))
      redmine_branch = get_issue_rudder_branch(issue)
      redmine_version = redmine_branch
      pull_id = m.groups('pull_id')[0]
      print(pull_id)
      if redmine_branch == "master":
        branch_version = redmine_branch
        agent_version = get_issue_rudder_version(issue) +"-nightly"
      else:
        ret = requests.get("http://www.rudder-project.org/release-info/rudder/versions/" + redmine_version + "/git_branch")
        branch_version = ret.text
        agent_version = redmine_version

      test_shell_on("agent", export_prefix + ";sh /tmp/ncf-setup test-pr https://github.com/Normation/ncf.git#" + branch_version + " ci/rudder-" + agent_version + " " + pull_id + " --testinfra", live_output=True)
    # Testing a ncf version
    else:
      if not cfengine_version:
        cfengine_version = "ci/rudder-" + tag + "-nightly"
      ret = requests.get("http://www.rudder-project.org/release-info/rudder/versions/" + tag + "/git_branch")
      branch_version = ret.text

      if scenario.platform.hosts ['agent'].info['system'] not in need_external_setup:
        ncf_version = "https://github.com/Normation/ncf.git#" + branch_version
      test_shell_on("agent", export_prefix + ";sh /tmp/ncf-setup test-local " + ncf_version + " " + cfengine_version + " --testinfra", live_output=True)

    # Re-dumping test results
    shell_on("agent", "find /tmp/tmp* -name \"test.log\" | xargs cat", live_output=True);
    shell_on("agent", "find /tmp/tmp* -name \"summary.log\" | xargs cat", live_output=True);

    finish()
