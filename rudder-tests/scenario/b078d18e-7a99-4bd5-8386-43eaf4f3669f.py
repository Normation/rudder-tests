"""
Test debian cis 1.1.1.1 Ensure mounting of freevxfs filesystems is disabled

At init time, the module is not loaded nor disabled

* RUN in audit for non compliance
* load the module
* RUN in audit for double non compliance
* RUN in enforce for repaired
* test that the module is unloaded and disabled
* RUN in enforce for success everywhere
* RUN in audit for success everywhere
* TODO add skip property
* TODO RUN to test that the directive is skipped (result_na)

"""
import os
from .lib import ScenarioInterface

class Report():
    def __init__(self, technique="*", status="*", ruleId="*", directiveId="*", versionId="*", component="*", key="*", timeStamp="*", nodeId="*", message="*"):
      self.technique = technique
      self.status = status
      self.ruleId = ruleId
      self.directiveId = directiveId
      self.versionId = versionId
      self.component = component
      self.key = key
      self.timeStamp = timeStamp
      self.nodeId = nodeId
      self.message = message

    def __repr__(self):
        return "@@%s@@%s@@%s@@%s@@%s@@%s@@%s@@%s##%s@#%s"%(self.technique, self.status, self.ruleId, self.directiveId, self.versionId, self.component, self.key, self.timeStamp, self.nodeId, self.message)

class Scenario(ScenarioInterface):
  def __init__(self, name, datastate):
    super().__init__(name, datastate)
    self.username = "user_test"

  def execute(self):
    self.start()
    technique = "CIS_debian9___Disable_kernel_module_loading"
    ruleId = "e12b9720-66c0-4887-8026-f72cdc423a69"
    directiveId = "b078d18e-7a99-4bd5-8386-43eaf4f3669f"
    nodeId = "root"

    condition_report            = Report(component="condition_from_variable_existence", key="skip_item_" + directiveId, nodeId=nodeId)
    kernel_configuration_report = Report(component="kernel_module_configuration",       key="freevxfs",                 nodeId=nodeId)
    kernel_not_loaded_report    = Report(component="kernel_module_not_loaded",          key="freevxfs",                 nodeId=nodeId)
    expected_reports = {
                         "condition_report": condition_report,
                         "kernel_configuration_report": kernel_configuration_report,
                         "kernel_not_loaded_report": kernel_not_loaded_report
                       }

    # Create Test rule
    self.run('localhost', 'create_rule', DIRECTIVES=directiveId, RULE_ID=ruleId, TARGETS="policyServer:root")
    # Remove /etc/modprobe.d/managed_by_rudder.conf if it already exists
    self.run('server', 'run_command', COMMAND="rm -f /etc/modprobe.d/managed_by_rudder.conf")
    # Unload freevxfs if already loaded
    self.run('server', 'run_command', COMMAND="rmmod freevxfs || true")

    # RUN in audit (1 non compliant)
    self.run('localhost', 'directive_policy_mode', DIRECTIVE_ID=directiveId, POLICY_MODE="audit")
    expected_reports["condition_report"].status = "audit_compliant"
    expected_reports["kernel_configuration_report"].status = "audit_noncompliant"
    expected_reports["kernel_not_loaded_report"].status = "audit_compliant"

    self.run('server', 'run_command', COMMAND="rudder agent update")
    self.run('server', 'report', REPORTS="\n".join(map(str, expected_reports.values())))

    # LOAD module
    # $ is espaced since the command is run through a ssh wrapper
    self.run('server', 'run_command', COMMAND="rudder agent update")
    self.run('server', 'run_command', COMMAND="find /lib/modules/\$(uname -r)/kernel/fs/ | grep freevxfs.ko | xargs insmod")

    # RUN in audit (2 non-compliant)
    expected_reports["kernel_not_loaded_report"].status = "audit_noncompliant"
    self.run('server', 'run_command', COMMAND="rudder agent update")
    self.run('server', 'report', REPORTS="\n".join(map(str, expected_reports.values())))

    # RUN in enforce mode (2 repaired)
    self.run('localhost', 'directive_policy_mode', DIRECTIVE_ID=directiveId, POLICY_MODE="enforce")
    expected_reports["condition_report"].status = "result_success"
    expected_reports["kernel_configuration_report"].status = "result_repaired"
    expected_reports["kernel_not_loaded_report"].status = "result_repaired"
    self.run('server', 'run_command', COMMAND="rudder agent update")
    self.run('server', 'report', REPORTS="\n".join(map(str, expected_reports.values())))

    # VERIFY that the module is unloaded
    self.run('server', 'run_command', COMMAND="lsmod | grep -q freevxfs", EXIT_STATUS="1")
    # VERIFY that the module is disabled
    self.run('server', 'run_command', COMMAND="modprobe -n -v freevxfs | grep -q 'install /bin/false'")

    # RUN in enforce mode (2 success)
    expected_reports["condition_report"].status = "result_success"
    expected_reports["kernel_configuration_report"].status = "result_success"
    expected_reports["kernel_not_loaded_report"].status = "result_success"
    self.run('server', 'run_command', COMMAND="rudder agent update")
    self.run('server', 'report', REPORTS="\n".join(map(str, expected_reports.values())))

    # Remove directive from test rule
    self.run('localhost', 'remove_directive_from_rule', DIRECTIVE_ID="8971d9c9-615a-491a-851f-d124cc09f188", RULE_ID=ruleId)
    self.run('localhost', 'rule_delete', RULE_ID=ruleId)
    self.finish()
