import json
import os
import shutil
import copy
import re
import sys
import importlib
import signal
import scenario.lib
# Hack to import rudder lib, remove, some day ...
sys.path.insert(0, "./rudder-api-client/lib.python")
from rudder import RudderEndPoint, RudderError
from . import Host
from .utils import shell

def init_vagrantfile():
  """ Initialize an empty Vagrantfile """
  if os.path.isfile("Vagrantfile"):
    return
  with open("Vagrantfile", "w") as vagrant:
    vagrant.write("""# -*- mode: ruby -*-
# vi: set ft=ruby :

# Network to use for first platform
$NETWORK="192.168.0.0/24"
# Number of ip to skip per network (1 for vagrant 5 for aws)
$SKIP_IP=1

# name of your ssh keypair
$AWS_KEYNAME='xxx'
# Path of the private key file
$AWS_KEYPATH="./xxx.pem"
# Subnet id in the VPC (id, not name)
$AWS_SUBNET='subnet-0760ec7afa0c7448e'
# Security group id in the VPC (id not name)
$AWS_SECURITY_GROUP='sg-062906d71ed329ae8'

# Credential for private repository (used for licenses and plugins)
$DOWNLOAD_USER="demo-normation"
$DOWNLOAD_PASSWORD="xxx"

require_relative 'vagrant.rb'

Vagrant.configure("2") do |config|
  config.vm.provider 'virtualbox' do |v|
      v.linked_clone = true if Vagrant::VERSION =~ /^1.8/
  end
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

### AUTOGEN TAG

end
""")

class Platform:
  """ A test platform
  Can be setup or teared down at once
  Can be used to run a test scenario
  """
  def __init__(self, name, override={}):
    self.name = name
    self.hosts = {}
    self.provider = "virtualbox"
    self.override = override
    self.has_relay = False
    init_vagrantfile()
    filename = "platforms/" + name + ".json"
    if not os.path.isfile(filename):
      print("Platform " + name + " does not exist")
      exit(1)
    platform_info = load_json(filename)

    # manage default values
    default = platform_info['default']

    for hostname, host in platform_info.items():
      if hostname == "default":
        continue
      host_info = copy.deepcopy(default)
      if not "provider" in host_info:
        host_info["provider"] = self.provider
      else:
        self.provider = host_info["provider"]
      host_info.update(host)
      host_info.update(override)
      if 'rudder-setup' in host_info and 'relay' in host_info['rudder-setup']:
        self.has_relay = True
      self.hosts[hostname] = Host(name, hostname, host_info)

    # add the scale out plugin when we have a relay
    if self.has_relay:
      if 'plugins' in self.override:
        if self.override['plugins'] != "all":
          self.override['plugins'] += " rudder-plugin-scale-out-relay"
      else:
        self.override['plugins'] = "rudder-plugin-scale-out-relay"

  def sorted_hosts(self):
    # use same order as vagrant.rb
    def key(name):
      setup = self.hosts[name].info['rudder-setup']
      prio = { 'server': '0', 'relay': '1', 'agent': '2' }
      if setup in prio:
        return prio[setup] + name
      else:
        return '9' + name
    return sorted(self.hosts.keys(), key=key)

  def setup(self, client_path, fail_exit=False):
    """ Startup the full platform """
    self.reset_platform()
    # guess the server if there is one
    server = None
    for host in self.hosts.values():
      if 'server' in host.info['rudder-setup']:
        server = host

    # do the startup procedure
    for hostname in self.sorted_hosts():
      host = self.hosts[hostname]
      ret = host.start()
      if ret != 0 and fail_exit:
        print("Startup failed with code " + str(ret))
        exit(ret)
      setup = host.info['rudder-setup']
      if server is not None and setup != "server":
        # accept agents
        if setup == "relay" or setup == "agent":
          (code,uuid) = host.run_with_ret_code("cat /opt/rudder/etc/uuid.hive", fail_exit=fail_exit)
          # Nothing else can be done if we don't have an installed agent
          if code != 0:
            print("Rudder agent installation seems to have failed, skipping acceptation")
            continue
          uuids = [uuid]
          # get relay chain
          relays = []
          cur = host
          while 'server' in cur.info and self.hosts[cur.info['server']] != server:
            next = self.hosts[cur.info['server']]
            relays.append(next)
            uuids.append(next.run("cat /opt/rudder/etc/uuid.hive", fail_exit=fail_exit))
            cur = next

          # run agent on the server pre 6.0 and on the whole relay chain
          if server.get_version() < 6.0:
            for h in relays:
              h.run("rudder agent run", quiet=False, live_output=True, fail_exit=fail_exit)
            server.run("rudder agent run", quiet=False, live_output=True, fail_exit=fail_exit)
          # we need the date on the server since it is where we compare at the end
          date0 = server.run("date +%s%3N", fail_exit=fail_exit)
          # accept
          curl_cmd = 'curl --insecure --silent --header \\"X-API-Token: \\$(cat /var/rudder/run/api-token)\\"'
          status_cmd = curl_cmd + ' https://localhost/rudder/api/latest/nodes/' + uuid + " | grep -q success"
          accept_cmd = curl_cmd + ' --request POST https://localhost/rudder/api/latest/nodes/pending/' + uuid + ' --data \\"status=accepted\\"'
          print("Waiting for acceptation of " + uuid)
          if not server.wait_for_command(status_cmd)  and fail_exit:
            exit(1)
          server.run(accept_cmd, quiet=False, live_output=True, fail_exit=fail_exit)

        # register relays
        if setup == "relay":
          date0 = server.run("date +%s%3N", fail_exit=fail_exit) # just in case generation happened before promotion
          if server.get_version() < 6.1:
            server.run("/opt/rudder/bin/rudder-node-to-relay "+uuid, quiet=False, live_output=True, fail_exit=fail_exit)
            server.run("curl --insecure https://localhost/rudder/api/deploy/reload", quiet=False, live_output=True, fail_exit=fail_exit)
          else:
            server.run("rudder server node-to-relay "+uuid, quiet=False, live_output=True, fail_exit=fail_exit)

        # wait for new generation
        if setup == "relay" or setup == "agent":
          uuids.reverse()
          if not server.wait_for_generation("/share/".join(uuids), date0) and fail_exit:
            exit(1)
          if len(uuids) > 1:
            # wait for generation on the first relay to make sure it gets the agent acceptation rules
            uuids.pop()
            if not server.wait_for_generation("/share/".join(uuids), date0) and fail_exit:
              exit(1)
  
          # update promises on the whole chain
          relays.append(server)
          relays.reverse()
          for h in relays:
            h.run("rudder agent run -u", quiet=False, live_output=True, fail_exit=fail_exit)
          host.run("rudder agent run -ui", quiet=False, live_output=True, fail_exit=fail_exit)

  def reset_platform(self):
    """ Update or replace the Vagrantfile configuration for the given platform """
    lines = []
    # parse Vagrantfile into the lines array (and update it)
    with open("Vagrantfile", "r+") as fd:
      updated = False
      line = fd.readline()
      max_pf_id = 0
      ids = []
      header_re = re.compile(r'### AUTOGENERATED FOR PLATFORM (\w+) \((\d+)\)')
      while line:
        # find max platform id so that we can add a new one if needed
        m = header_re.match(line)
        if m:
          pf_id = int(m.group(2))
          ids.append(pf_id)
          if pf_id > max_pf_id:
            max_pf_id = pf_id
        # look for the platform we want to modify and update its content
        if not updated and m and m.group(1) == self.name:
          lines.append(line) # re-add the header
          pf_id = int(m.group(2))
          while not re.match(r'### END OF AUTOGENERATION FOR ' + self.name, line):
            line = fd.readline()
          lines.extend("platform(config, " + str(pf_id) + ", '" + self.name + "', " + str(self.override) + ")\n")
          lines.append(line) # re-add the footer
          updated = True
        # no existing platform, create a new one
        elif not updated and re.match(r'### AUTOGEN TAG', line):
          # Look for an available id between 1 and max_pf_id+1 (max_pf_id+1 is always available)
          next_id = [ x for x in range(1, max_pf_id+2) if not x in ids ][0]
          if next_id >= 256:
            print(" New platform id will be "+next_id+" which will fail (invalid ip, ...) , please delete some platform before creating a new one")
            exit(6)
          if self.provider == "aws":
            lines.append('### AUTOGENERATED FOR PLATFORM ' + self.name + " (" + str(next_id) + ") aws: see vagrant ssh-config for address\n")
          else:
            lines.append('### AUTOGENERATED FOR PLATFORM ' + self.name + " (" + str(next_id) + ") https://localhost:" + str(80+next_id) + "81/ \n")
          lines.extend("platform(config, " + str(next_id) + ", '" + self.name + "', " + str(self.override) + ")\n")
          lines.append('### END OF AUTOGENERATION FOR ' + self.name + "\n")
          lines.append("\n### AUTOGEN TAG\n")
          updated = True
        # unknown Vagrantfile line, keep it
        else:
          lines.append(line)
        line = fd.readline()
      # rewrite the file
      fd.seek(0)
      fd.truncate()
      fd.writelines(lines)

  def export(self):
    """ Export the full platform in a tgz """
    # This is virtualbox/vagrant specific and should be refactored when we add a new provider
    dirname = os.getcwd() + "/rtf-" + self.name
    if not os.path.exists(dirname):
      os.mkdir(dirname)

    # create ssh configuration early since it can fail (fail early)
    keydir = dirname + "/keys"
    if not os.path.exists(keydir):
      os.mkdir(keydir)
    with open(dirname+'/ssh_config', 'w') as outfile:
      for host in self.hosts.values():
        outfile.write(host.ssh_config(keydir))

    # create vm dumps
    for host in self.hosts.values():
      host.export(dirname)

    print("Creating package")
    # create startup script
    with open(dirname+'/run', 'w') as outfile:
      outfile.write("#!/bin/sh\n")
      for host in self.hosts.values():
        outfile.write("VBoxManage registervm $(pwd)/" + host.hostid + "/" + host.hostid + ".vbox\n")
        outfile.write('UUID=$(VBoxManage list vms | grep "\\"' + host.hostid + '\\"" | ' + "perl -pe 's/.*\{(.*)\}.*/$1/')\n")
        outfile.write("VBoxManage startvm $UUID --type headless\n")
      outfile.write("echo ''\n")
      outfile.write("echo 'You can now connect to VMs using ssh -F ssh_config <vmname>'\n")
      outfile.write("echo 'Available VMs are: '\n")
      for host in self.hosts.values():
        outfile.write("echo '"+host.hostid+"'\n")
      outfile.write("echo ''\n")
    os.chmod(dirname+'/run', 0o755)
    # create shutdown script
    with open(dirname+'/terminate', 'w') as outfile:
      outfile.write("#!/bin/sh\n")
      for host in self.hosts.values():
        outfile.write('UUID=$(VBoxManage list vms | grep "\\"' + host.hostid + '\\"" | ' + "perl -pe 's/.*\{(.*)\}.*/$1/')\n")
        outfile.write("[ -n \"$UUID\" ] && VBoxManage controlvm $UUID poweroff\n")
        outfile.write("[ -n \"$UUID\" ] && VBoxManage unregistervm $UUID\n")
      outfile.write("echo 'You can now safely remove this directory!'\n")
    os.chmod(dirname+'/terminate', 0o755)

    # Create tgz
    os.system("tar czf rtf-" + self.name + ".tgz " + os.path.basename(dirname))
    shutil.rmtree(dirname)

  def export_ova(self):
    """ Export each machines in the platform as a separate ova """
    # This is virtualbox/vagrant specific and should be refactored when we add a new provider
    dirname = os.getcwd() + "/vms-" + self.name
    if not os.path.exists(dirname):
      os.mkdir(dirname)

    for host in self.hosts.values():
      # no selinux to avoid nasty bugs
      #host.run("sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config || true")
      # reconfigure network ?
      # stop
      host.halt()

    i = 0
    for host in self.hosts.values():
      uuid = os.popen("VBoxManage list vms | grep '" + host.hostid + "' | perl -pe 's/.*\{(.*)\}.*/$1/'").read().strip()
      host.uuid = uuid

      # configure host network ?

      for line in os.popen("VBoxManage showvminfo " + uuid + " --machinereadable"):
        # remove vagrant share
        match = re.match(r'SharedFolderName.*="(.*)"', line)
        if match:
          os.system("VBoxManage sharedfolder remove " + uuid + " --name " + match.group(1))
        # remove redirects
        match = re.match(r'Forwarding.*="(.*?),.*"', line)
        if match:
          os.system("VBoxManage modifyvm " + uuid + " --natpf1 delete " + match.group(1))
      # reconfigure redirects
      port = 2022+i
      i += 1
      os.system("VBoxManage modifyvm " + uuid + " --natpf1 \"ssh,tcp,127.0.0.1," + str(port) + ",,22\"")
      if host.info['rudder-setup'] == 'server':
        os.system("VBoxManage modifyvm " + uuid + " --natpf1 \"tcp80,tcp,,8080,,80\"")
        os.system("VBoxManage modifyvm " + uuid + " --natpf1 \"tcp443,tcp,,8081,,443\"")

      # add video memory and rename
      os.system("VBoxManage modifyvm " + uuid + " --name " + host.name + " --vram 32")

      # export
      os.system("VBoxManage export " + uuid + " -o " + dirname + "/" + host.name + ".ova --ovf09 --manifest")

    # cleanup, those VMs are not suitable anymore for rtf
    # Just comment since the user may want to do things again and reexport
    print("The platform " + self.name + " is not suitable for use with rtf anymore.")
    print("Please destroy the VMs when you don't need them anymore, either with virtualbox interface or via those commands:")
    for host in self.hosts.values():
      print("VBoxManage unregistervm " + host.uuid + " --delete")

  def shutdown(self):
    """ Stop the full platform """
    for host in self.hosts.values():
      host.halt()

  def snapshot(self, name):
    """ Snapshot the full platform """
    for hostname in self.sorted_hosts():
      self.hosts[hostname].snapshot(name or "rtf_snap")

  def rollback(self):
    """ Rollback from last snapshot the full platform """
    # rollback must be done in reverse to avoid having snapshot inventories going to a rollbacked server
    hostlist = self.sorted_hosts()
    hostlist.reverse()
    for hostname in hostlist:
      self.hosts[hostname].rollback(name or "rtf_snap")

  def snapshot_delete(self):
    """ Rollback from last snapshot the full platform """
    for hostname in self.sorted_hosts():
      self.hosts[hostname].snapshot_delete(name or "rtf_snap")

  def teardown(self):
    """ Stop and destroy the full platform """
    for host in self.hosts.values():
      host.stop()

    # Update or replace the Vagrantfile configuration by removing the given platform """
    lines = []
    # parse Vagrantfile into the lines array (and update it)
    with open("Vagrantfile", "r+") as fd:
      updated = False
      line = fd.readline()
      matched = False
      while line:
        if re.match(r'^### AUTOGENERATED FOR PLATFORM ' + self.name + ' .*', line):
          matched = True
        if not matched:
          lines.append(line)
        if re.match(r'^### END OF AUTOGENERATION FOR ' + self.name + '$', line):
          # Remove trailing new line
          line = fd.readline()
          matched = False
        line = fd.readline()
      # rewrite the file
      fd.seek(0)
      fd.truncate()
      fd.writelines(lines)

  def push_techniques(self, directory):
    print("Pushing technique to host")
    for host in self.hosts.values():
      if host.info['rudder-setup'] == 'server':
        host.push_techniques(directory)

  def share(self):
    """ Share the platform via vagrant cloud """
    # Some of this is vagrant specific, it should be refactored when we add a new provider
    password = "password" # this can be a security risk, but:
                          #    it's only test machines
                          #    you need to know they are running
                          #    you need to know their share ID
    # Check that the user is logged in
    code = os.system("vagrant login -c")
    if code != 0:
      print("You need an atlas hashicorp login to use this feature.")
      print("Go to https://atlas.hashicorp.com/ to create one.")
      print("")
      print("If you already have an account, type 'vagrant login' and then re-run this command.")
      exit(4)
    signal.signal(signal.SIGINT, empty_handler)
    signal.signal(signal.SIGTERM, empty_handler)
    # share
    shared_process = []
    for host in self.hosts.values():
      shared_process.append(host.share(password))
    # display info
    print("")
    print("Now you can tell your coworker to run the following commands (he needs atlas account too):")
    print("")
    print("vagrant login")
    for (hostid, cmd, process) in shared_process:
      print(cmd + "   # " + hostid)
    print("")
    # wait for ctrl-c and propagate it to stop sharing
    print("Press ctrl-c to stop sharing")
    signal.pause()
    print("Unsharing")
    for (hostid, cmd, process) in shared_process:
      process.sendintr()
      process.wait()

  def update_rudder(self, version, fail_exit):
    """ Update rudder version on all hosts """
    self.reset_platform()
    for hostname in self.sorted_hosts():
      host = self.hosts[hostname]
      code = host.reprovision()
      if fail_exit and code != 0:
        print("Upgrade error")
        exit(code)

  def status(self):
    """ Show platform status """
    host_list = [self.name + '_' + h for h in self.hosts.keys()]
    os.system("vagrant status " + " ".join(host_list))

  def api_connection_info(self):
    """ Get informations to connect to the server via the api """
    rudder_url = None
    token = None
    for hostname, host in self.hosts.items():
      if host.info['rudder-setup'] == "server":
        rudder_url = host.get_url()
        token = host.run('cat /var/rudder/run/api-token')
    if rudder_url is None or token is None:
      rudder_url = ''
      token = ''
    #  print("This platform has no rudder server, can't run this command")
    #  exit(2)
    return (rudder_url, token)

  def run_scenario(self, name, frmt, run_finally, err_stop, run_only, client_path, params, startTestNumber, destroyOnError=False, json_file=None):
    """ Run a scenario on this platform """
    try:
      # test ruby binary
      (code, rubyver) = shell("ruby --version")
      if re.match(r'jruby', rubyver):
        if not re.match(r'jruby 1.7', rubyver):
          print("WARNING: this is not JRuby 1.7, compatibility unknown")

      elif not re.match(r'ruby 2', rubyver):
        print("ERROR: MRI Ruby needs to be version 2")
        exit(3)

      # Test rspec command
      rspec = "ruby -S rspec --order defined --fail-fast --format " + frmt
      shell(rspec)

      # Get api command line
      (rudder_url, token) = self.api_connection_info()
      rcli = "rudder-cli --skip-verify --url=" + rudder_url + " --token=" + token

      # load and run
      parameters = {}
      for param in params:
        kv = param.split('=')
        parameters[kv[0]] = kv[1]
      scenario.lib.scenario = scenario.lib.Scenario(self, rspec, rcli, frmt, run_only, run_finally, err_stop, parameters, startTestNumber)
      scenario.lib.setenv(client_path, rudder_url, token)
      module = importlib.import_module("scenario." + name)

      scenario_to_run = getattr(module, "Scenario")
      if json_file is not None:
        with open(json_file) as f:
          data = json.load(f)
      else:
          data = None
      s = scenario_to_run(data)
      s.run()

      if scenario.lib.scenario.errors:
        print("Test scenario '"+ name +"' failed on platform '" + self.name + "'")
        exit(5)
    finally:
      if destroyOnError:
        self.teardown()

  def print_environment(self, client_path):
    """ Print environment used to run tests on this platform """
    (rudder_url, token) = self.api_connection_info()
    scenario.lib.setenv(client_path, rudder_url, token)
    print("export PATH=" + os.environ['PATH'])
    print("export PYTHONPATH=" + os.environ['PYTHONPATH'])
    print("export RUDDER_SERVER=" + os.environ['RUDDER_SERVER'])
    print("export RUDDER_TOKEN=" + os.environ['RUDDER_TOKEN'])
    print("alias rcli='rudder-cli --skip-verify --url=" + rudder_url + " --token=" + token + "'")

  def export_test(self, rule_uuid, test_name, scenario=False):
    """ Export a given rule, for use in a test or a scenario """
    # Retrieve data
    (rudder_url, token) = self.api_connection_info()
    endpoint = RudderEndPoint(rudder_url, token, verify=False)
    rule = endpoint.rule_details(rule_uuid)['rules'][0]
    directives = []
    for directive_uuid in rule['directives']:
      directive = endpoint.directive_details(directive_uuid)['directives'][0]
      del directive['id']
      directives.append(directive)

    # create test files
    rule_file = "spec/tests/"+test_name+"_rule.rb"
    test_file = "spec/tests/"+test_name+"_test.rb"
    scenario_file = "scenario/"+test_name+".py"

    make_rule_testfile(rule_file, rule, directives)
    make_user_testfile(test_file)
    print("""
A test file to add the rule via the API has been created in %(rule_file)s
This file is where you can make change to the generated rule or directive, but it works as is.

A generic test file to test if the rule has been properly applied has been created in %(test_file)s
It contains demo code, but since we don't know what the rule does it doesn't contain code.
-> Pleas edit %(rule_file)s !

Add the test to an existing scenario:
- Add the following line before the call to wait_for_generation on all agents
    run('localhost', '%(test_name)s_rule', Err.BREAK, NAME="Test %(test_name)s", GROUP="special:all")
- Add the following line after the call to wait_for_generation
    run_on("agent", ''%(test_name)s_test', Err.CONTINUE)
- Add the following lines before the removal of the agent nodes
    run('localhost', 'directive_delete', Err.FINALLY, DELETE="%(directive_name)s", GROUP="special:all")
    run('localhost', 'rule_delete', Err.FINALLY, DELETE="%(rule_name)s", GROUP="special:all")
""" % {'rule_file': rule_file, 'test_file': test_file, 'test_name': test_name,
       'directive_name': directive['displayName'], 'rule_name': rule['displayName']
      })
    if scenario:
      make_scenario_file(scenario_file, test_name)
      print("Additionnaly, a scenario has been created in " + scenario_file)

  def export_technique_test(self, directive_uuid, test_name, path):
    """ Export a technique test data, for use in a technique test, in the given path """

    # Test destination directory
    if not os.path.isdir(path):
      print("The " + path + " path does not exist.")
      exit(1)

    # Retrieve data
    (rudder_url, token) = self.api_connection_info()
    endpoint = RudderEndPoint(rudder_url, token, verify=False)

    file_check = test_name + ".rb"
    file_metadata = test_name + ".metadata"
    file_directive = test_name + ".json"

    # Generate metadata
    metadata = {}
    metadata["inits"] = []
    metadata["checks"] = [file_check]
    metadata["directives"] = [file_directive]
    metadata["sharedFiles"] = []
    metadata["compliance"] = 100

    make_jsonfile(os.path.join(path, file_metadata), metadata)

    # Generate check file
    make_user_testfile(os.path.join(path, file_check))

    # Generate directive
    directive = endpoint.directive_details(directive_uuid)['directives'][0]

    # This is needed because of #8687, the API does not know these parameters at creation
    if "isEnabled" in directive:
      del directive["isEnabled"]
    if "isSystem" in directive:
      del directive["isSystem"]
    if "priority" in directive:
      del directive["priority"]
    if "tags" in directive:
      del directive["tags"]
    if "policyMode" in directive:
      del directive["policyMode"]
    if "system" in directive:
      del directive["system"]
    if "id" in directive:
      del directive["id"]


    make_jsonfile(os.path.join(path, file_directive), directive)

    print("""
The test content has been generated in %s, it contains:

- %s which contains the metatdata, automatically filled. You can edit the expected compliance (default is 100)
- %s which contains the directive parameters, automatically filled.
- %s which is a stub check file. You need to edit it to describe the expected state
  -> Please edit it!
""" % (path, file_metadata, file_directive, file_check))

  def dump_datastate(self):
      effective_hosts = {}
      for host in self.hosts:
        host_infos = {}
        hostname = self.name + "_" + host

        # Role and role based infos
        if 'rudder-setup' in self.hosts[host].info:
            host_infos['role'] = self.hosts[host].info['rudder-setup']
            if host_infos['role'] == "server":
                host_infos['webapp_url'] = self.hosts[host].get_url()
        # Basic platform infos
        host_infos.update(self.hosts[host].info)

        # Vagrant ssh infos
        (code, output) = shell("vagrant ssh-config " + hostname, fail_exit=False, quiet=True)
        user_re = re.compile(r'User (\S+)')
        hostname_re = re.compile(r'HostName (\S+)')
        port_re = re.compile(r'Port (\S+)\s*')
        creds_re = re.compile(r'IdentityFile (.+)')


        for line in [l.strip() for l in output.split('\n')]:
            m = user_re.match(line)
            if m:
              host_infos["ssh_user"] = str(m.group(1))

            m = hostname_re.match(line)
            if m:
              host_infos["ip"] = str(m.group(1))

            m = port_re.match(line)
            if m:
              host_infos["ssh_port"] = int(m.group(1))

            m = creds_re.match(line)
            if m:
              host_infos["ssh_cred"] = str(m.group(1))

        effective_hosts[hostname] = host_infos
      print(json.dumps(effective_hosts, sort_keys=True, indent=2))


###################
# Utility methods #
###################

def empty_handler(signum, frame):
  pass

def load_json(filename):
  """ Load a commented json """
  # read json from file
  file = open(filename, 'r')
  data = file.read()
  file.close()
  data = re.sub("\\/\\/.*", "", data)
  try:
    return json.loads(data)
  except Exception as e:
    print("JSON syntax error in " + filename)
    print(e.message)
    exit(3)

def make_jsonfile(filename, content):
  with open(filename, "w") as fd:
    fd.write('[')
    fd.write(json.dumps(content, sort_keys=True, indent=2, separators=(',', ': ')))
    fd.write(']')

def make_rule_testfile(filename, rule, directives):
  with open(filename, "w") as fd:
    data = """# File generated using rtf test from-rule
# This test creates a rule named '%(displayName)s' and its directive(s)
# And is checks that the api returned correctly

require 'spec_helper'

group = $params['GROUP']

directiveFile = "/tmp/directive.json"
ruleFile = "/tmp/rule.json"

describe "Add a test directive and a rule"  do
      """ % {'displayName': rule['displayName']}
    for idx, directive in enumerate(directives):
      data += """
  # Add directive
  describe command($rudderCli + " directive create --json=" + directiveFile + " %(technique)s %(name)s") do
    before(:all) {
      File.open(directiveFile, 'w') { |file|
        file << <<EOF
%(directive)s
EOF
      }
    }
    after(:all) {
      File.delete(directiveFile)
    }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^"[0-9a-f\\-]+"$/ }
    it {
      # register output uuid for next command
      $uuid%(id)i = subject.stdout.gsub(/^"|"$/, "").chomp()
    }
  end

""" % {'technique': directive['techniqueName'], 'name': directive['displayName'], 'directive': json.dumps(directive, indent=2), 'id': idx}
    data += """
  # create a rule
  describe command($rudderCli + " rule create --json=" + ruleFile + " testRule") do
    before(:all) {
      File.open(ruleFile, 'w') { |file|
        file << <<EOF
{
  "directives": [
"""
    data += ",".join(['"#{$uuid' + str(i) + '}"' for i in range(0, len(directives))])
    data += """
  ],
  "displayName": "%(displayName)s Rule",
  "longDescription": "%(longDescription)s ",
  "shortDescription": "%(shortDescription)s",
  "targets": [
    {
      "exclude": {
        "or": []
      },
      "include": {
        "or": [
          "#{group}"
        ]
      }
    }
  ]
}
EOF
      }
    }
    after(:all) {
      File.delete(ruleFile)
    }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^"[0-9a-f\\-]+"$/ }
    it {
      # register output uuid for next command
      $uuid = subject.stdout.gsub(/^"|"$/, "").chomp()
    }
  end

end
""" % {'displayName': rule['displayName'], 'longDescription': rule['longDescription'], 'shortDescription': rule['shortDescription']}
    fd.write(data)

def make_user_testfile(filename):
  with open(filename, "w") as fd:
    fd.write("""# Sample file generated using rtf test from-rule
# This is where you test your rule

require 'spec_helper'

# Please add your test here
# see http://serverspec.org/resource_types.html for a full documentation of available tests

## Ex: Test that a a package has been installed
#describe package'apache2') do
#  it { should be_installed }
#  it { should be_installed.with_version('2.4.10') }
#end

## Ex: Test that a user exist
#describe user('testuser') do
#  it { should exist }
#  it { should have_home_directory '/home/testuser' }
#end

## Ex: Test that a file exists
#describe file('/etc/passwd') do
#  it { should be_file }
#  it { should be_mode 640 }
#  it { should be_owned_by 'root' }
#  its(:content) { should match /regex to match/ }
#end

## Ex: Test the output of a command
#describe command('ls -al /') do
#  its(:stdout) { should match /bin/ }
#  its(:stderr) { should match /No such file or directory/ }
#  its(:exit_status) { should eq 0 }
#end
""")

def make_scenario_file(filename, test_name):
  with open(filename, "w") as fd:
    fd.write("""# File generated using rtf test from-rule
from scenario.lib import *

# test begins, register start time
start()

run_on("all", 'agent', Err.CONTINUE)

# force inventory
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="inventory")
run_on("server", 'run_agent', Err.CONTINUE, PARAMS="run")

# accept nodes
for host in scenario.nodes("agent"):
  run('localhost', 'agent_accept', Err.BREAK, ACCEPT=host)

# Add a rule
date0 = host_date('wait', Err.CONTINUE, "server")
run('localhost', '%(test_name)s_rule', Err.BREAK, NAME="Test %(test_name)s", GROUP="special:all")
for host in scenario.nodes("agent"):
  wait_for_generation('wait', Err.CONTINUE, "server", date0, host, 20)

# Run agent
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="update")
run_on("agent", 'run_agent', Err.CONTINUE, PARAMS="run")

# Test rule result
run_on("agent", '%(test_name)s_test', Err.CONTINUE)

# remove rule/directive
run('localhost', 'directive_delete', Err.FINALLY, DELETE="Test %(test_name)s Directive", GROUP="special:all")
run('localhost', 'rule_delete', Err.FINALLY, DELETE="Test %(test_name)s Rule", GROUP="special:all")

# remove agent
for host in scenario.nodes("agent"):
  run('localhost', 'agent_delete', Err.FINALLY, DELETE=host)

# test end, print summary
finish()
""" % {'test_name': test_name})

