"""
Scenario: upgrade

Generic scenario that tries many tests on a platform with or without a relay.
This is the base scenario that should be run to test a release.
"""
from scenario.lib import *
import os

# test begins, register start time
start(__doc__)

class Scenario():
  def __init__(self, data):
    self.data = data



  def run(self):
    ruleId = "32377fd7-02fd-43d0-aab7-28460a91347b"
    directiveId = "863c5887-4d99-4e08-8502-e9cda51f3a8e"
    print("Running apicall on localhost")
    #run('localhost', 'remove_directive_from_rule', Err.BREAK, DIRECTIVE_ID="8971d9c9-615a-491a-851f-d124cc09f188", RULE_ID=ruleId)
    #run('localhost', 'add_directive_to_rule', Err.BREAK, DIRECTIVE_ID=directiveId, RULE_ID=ruleId)

    def build_report(technique="*", status="*", ruleId="*", directiveId="*", versionId="*", component="*", key="*", timeStamp="*", nodeId="*", message="*"):
        return "@@%s@@%s@@%s@@%s@@%s@@%s@@%s@@%s##%s@#%s"%(technique, status, ruleId, directiveId, versionId, component, key, timeStamp, nodeId, message)

    expected_reports = [
      build_report(technique="userGroupManagement", status="result_success", ruleId=ruleId, directiveId=directiveId, component="Password", key="bob", nodeId="root")
    ]


    run('server', 'report', Err.BREAK, REPORTS="\n".join(expected_reports))
    finish()
