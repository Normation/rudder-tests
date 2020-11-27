"""
"""
from lib.scenario import ScenarioInterface
import re

class windows_update(ScenarioInterface):
  def __init__(self, name, datastate, scenario_input={}):
    schema = {
      "node": { "schema": { "$ref": "#host"} , "min": 1},
      "server": { "schema": { "$ref": "#rudder_server"} , "min": 1},
    }
    super().__init__(name, datastate, schema)
    self.input = scenario_input
    self.rudder_base = "C:/Program Files/Rudder"

  """
    Get Etag of the latest policies available for the node on the server side
  """
  def getEtag(self, agent, server):
    # Get last etag
    self.policy_server_ip = self.ssh_on(agent, "Get-content \"%s/etc/policy-server.conf\""%self.rudder_base)[1].strip()
    agent_id = self.ssh_on(agent, "Get-Content \"%s/etc/uuid.hive\""%self.rudder_base)[1].strip()

    powershell_curl = ' '.join(('&"' + self.rudder_base + '/bin/curl.exe"',
                                '--location',
                                '--insecure',
                                '--silent',
                                '--tlsv1.2',
                                '--fail',
                                '--cert "' + self.rudder_base + '/etc/ssl/localhost.cert:Rudder-dsc passphrase"',
                                '--key "' + self.rudder_base + '/etc/ssl/localhost.priv"',
                                '-X HEAD',
                                '-I "https://' + self.policy_server_ip + '/policies/' + agent_id + '/rules/dsc/rudder.zip"'))
    s = self.ssh_on(agent, powershell_curl)[1]
    p = re.compile("ETag:\s+\"([a-z0-9-]+)\"")
    m = p.search(s)
    if m:
      etag = m.group(1)
    else:
      raise Exception('etag not found')
    return etag

  """
    Remove etag content, this will force the update to download new policies
  """
  def resetEtag(self, agent):
    self.ssh_on(agent, "Clear-Content -Path \"" + self.rudder_base + "/policy/rudder.etag\"")

  """
    Remove recursively the content of a folder on the agent
  """
  def removeFolder(self, agent, folder):
    print(self.ssh_on(agent, "Get-ChildItem -Path \"" + folder + "\" -Recurse | Remove-Item -Force -Recurse")[1].strip())

  """
    Main scenario
  """
  def execute(self):
    self.start()
    agent = self.nodes("agent")[0]
    server = self.nodes("server")[0]
    zipFolder = self.rudder_base + "/tmp/rudder.zip"

    ###########################################################################
    # Test 1, modify etag on the node, update must succeed
    ###########################################################################
    etag = self.getEtag(agent, server)
    self.resetEtag(agent)
    self.run_testinfra(agent, "windows_update", ETAG=etag, UPDATE="to_update", NAME="test1")

    # Test 1Bis , rerun an update, it should do nothing
    self.run_testinfra(agent, "windows_update", ETAG=etag, UPDATE="keep", NAME="test1bis")


    ###########################################################################
    # Test 2, modify etag on the node, remove policy.bkp, update must succeed
    ###########################################################################
    etag = self.getEtag(agent, server)
    self.resetEtag(agent)
    self.removeFolder(agent, self.rudder_base + "/policy.swap")
    self.run_testinfra(agent, "windows_update", ETAG=etag, UPDATE="to_update", NAME="test2")

    ###########################################################################
    # Test 3, empty policy folder, update must succeed
    ###########################################################################
    etag = self.getEtag(agent, server)
    self.removeFolder(agent, self.rudder_base + "/policy")
    self.run_testinfra(agent, "windows_update", ETAG=etag, UPDATE="to_update", NAME="test3")

    ###########################################################################
    # Test 4, remove policy folder, update must succeed
    ###########################################################################
    etag = self.getEtag(agent, server)
    self.removeFolder(agent, self.rudder_base + "/policy")
    self.ssh_on(agent, "Remove-Item -Force -Recurse -Path \"%s\""%(self.rudder_base + "/policy"))
    self.run_testinfra(agent, "windows_update", ETAG=etag, UPDATE="to_update", NAME="test4")

    ###########################################################################
    # Test 5, change policy to localhost, must fail, policies must stay
    # unchanged
    ###########################################################################
    etag = self.getEtag(agent, server)
    self.ssh_on(agent, "\"%s\"| Out-File \"%s/etc/policy-server.conf\""%("127.0.0.1", self.rudder_base))
    self.run_testinfra(agent, "windows_update", ETAG=etag, UPDATE="fail")

    # Set the policy server back to its previous value
    self.ssh_on(agent, "\"%s\"| Out-File \"%s/etc/policy-server.conf\""%(self.policy_server_ip, self.rudder_base))

    ###########################################################################
    # Test 6, prevent policies removal by opening a file before the update
    # Should try to back up to backup policies
    # Before the update, modify a file to verify that it is correctly replaced
    # Etag should not change after update
    ###########################################################################
    etag = self.getEtag(agent, server)
    self.resetEtag(agent)
    file_to_lock = self.rudder_base + "/policy/ncf/10_ncf_internals/classes.ps1"
    self.ssh_on(agent, "\"%s\"| Out-File \"%s\""%("Non-sense content", file_to_lock))
    self.run_testinfra(agent, "windows_update", ETAG=etag, UPDATE="fallback-backup-policies", FILE_TO_LOCK=file_to_lock)

    # Set the policy server back to its previous value
    self.ssh_on(agent, "\"%s\"| Out-File \"%s/etc/policy-server.conf\""%(self.policy_server_ip, self.rudder_base))

    ###########################################################################
    # Test 7, prevent policies removal by opening a file before the update
    # Delete the policy.bkp folder
    # Should try to back up to initial policies
    # Etag should not change after update
    ###########################################################################
    etag = self.getEtag(agent, server)
    self.resetEtag(agent)
    file_to_lock = self.rudder_base + "/policy/ncf/10_ncf_internals/classes.ps1"
    self.removeFolder(agent, self.rudder_base + "/policy.bkp")
    self.ssh_on(agent, "\"%s\"| Out-File \"%s\""%("Non-sense content", file_to_lock))
    self.run_testinfra(agent, "windows_update", ETAG=etag, UPDATE="fallback-initial-policies", FILE_TO_LOCK=file_to_lock)

    # Set the policy server back to its previous value
    self.ssh_on(agent, "\"%s\"| Out-File \"%s/etc/policy-server.conf\""%(self.policy_server_ip, self.rudder_base))

    self.finish()
