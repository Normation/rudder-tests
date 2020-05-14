#!/usr/bin/env python

import re
import copy
import os
import json
import requests
import traceback
from subprocess import Popen, check_output, PIPE, CalledProcessError
from lxml import etree
from time import sleep
from datetime import datetime
from pprint import pprint

# This method is used to prevent running new test in cases of error
def enum(*sequential, **named):
  """ Enum compatibility for old python versions """
  enums = dict(zip(sequential, range(len(sequential))), **named)
  return type('Enum', (), enums)

# Error handling mode in scenario
Err = enum('CONTINUE', 'BREAK', 'FINALLY', 'IGNORE')
RudderLog = enum('APACHE', 'WEBAPP', 'ALL')

def shell(command, fail_exit=True, keep_output=True, live_output=False):
  print("+" + command)
  if keep_output:
    if live_output:
      process = Popen(command, shell=True, universal_newlines=True)
    else:
      process = Popen(command, stdout=PIPE, shell=True, universal_newlines=True)
    output, error = process.communicate()
    retcode = process.poll()
  else: # keep tty management and thus colors
    process = Popen(command, shell=True)
    retcode = process.wait()
    output = None
  if fail_exit and retcode != 0:
    print(command)
    print("*** COMMAND ERROR " + str(retcode))
    exit(1)
  return (retcode, output)

class ScenarioInterface:
  """ Holds a scenario data
  Most scenario related methods are global and not in this class to make scenario writing look like script writing
  """
  def __init__(self, name, datastate):
    self.name = name
    self.stop = False
    self.errors = False
    self.datastate = datastate
    self.rspec = "ruby -S rspec --order defined --fail-fast"
    self.token = ""
    self.__set_token()

  def __test_ruby_cli(self):
    try:
      # test ruby binary
      (code, rubyver) = shell("ruby --version")
      if re.match(r'jruby', rubyver):
        if not re.match(r'jruby 1.7', rubyver):
          print("WARNING: this is not JRuby 1.7, compatibility unknown")

      elif not re.match(r'ruby 2', rubyver):
        print("ERROR: MRI Ruby needs to be version 2")
        exit(3)
      shell(self.rcli)
    finally:
      print("ERROR: something went wrong while checking for ruby and rspec")
      exit(1)

  def __set_token(self):
    self.token = self.ssh_on(self.nodes("server")[0], "cat /var/rudder/run/api-token")[1]

  """
    Each serverspec call (== each call to a test) will produce a report xml file.
    We need to merge them at runtime, and hierachize the report per scenario
  """
  def __merge_reports(self):
    # Assume the report exists
    single_report_file = "/home/fdallidet/Rudder/rtfr/serverspec-result.xml"
    single_tree = etree.parse(single_report_file)

    try:
      global_report_file = "/home/fdallidet/Rudder/rtfr/result.xml"
      global_tree = etree.parse(global_report_file)
    except:
      global_tree = etree.ElementTree(etree.Element("testsuites", name=self.name))

    for element in single_tree.getroot().findall("testsuite"):
      global_tree.getroot().append(element)

    with open(global_report_file, 'wb+') as f:
      f.write(etree.tostring(global_tree))

  def nodes(self, kind = "all"):
    # kind not defined, return all nodes
    if (kind == "all"):
      return self.datastate.keys()
    else:
      nodes = []
      for hostname, host in self.datastate.items():
        if host.get("role", "None") == kind:
          nodes.append(hostname)
      return nodes

  def host_rudder_version(self, hostname):
    version_line = self.ssh_on(hostname, "rudder agent version")
    match = re.match(r'^Rudder agent (\d+)\.(\d+)\..*', version_line[1])
    if match:
      return (match.group(1), match.group(2))
    else:
      return ("", "")

  def ssh_on(self, host, command):
      infos = self.datastate[host]
      default_ssh_options = ["StrictHostKeyChecking=no", "UserKnownHostsFile=/dev/null"]
      options = "-o \"" + "\" -o \"".join(default_ssh_options) + "\""
      command = "sudo /bin/sh -c 'PATH=\\$PATH:/vagrant/scripts LANG=C " + command + "'"
      ssh_cmd = "ssh -i %s %s@%s -p %s %s \"%s\""%(infos["ssh_cred"], infos["ssh_user"], infos["ip"], infos["ssh_port"], options, command)
      return shell(ssh_cmd)

  def start(self):
    self.start = datetime.now().isoformat()
    print("[" + self.start + "] Begining of scenario" + self.name)


  def finish(self):
    """ Finish a scenario """
    self.end = datetime.now().isoformat()
    print("[" + self.end + "] End of scenario")

  # If there's been error in scenario, then only the test with Err.FINALLY must be run
  def should_run(self, test, mode):
    """ Return True when the test must be ran """
    if not self.stop:
      return True

    if mode != Err.FINALLY:
      return False
    else: # mode == Err.FINALLY
      return self.run_finally


  ############################################
  # Commands to be used in a scenario script #
  ############################################

  # Run a test
  # If the test starts with a /, then the full path of the test will be used,
  # otherwise it will look for a ruby script in specs/tests directory
  def run(self, target, test, error_mode=Err.CONTINUE, **kwargs):
    """ Run one test in a scenario without any log dump """
    return self.run_and_dump(target, test, error_mode, None, **kwargs)

  def run_and_dump(self, target, test, error_mode, rudder_log, **kwargs):
    """ Run one test in a scenario and rudder_log <rudder_log> log file if it fails
    error_mode can be :
     - CONTINUE: continue testing even if this fail, should be the default
     - BREAK: stop the scenario if this fail, for tests that change a state
     - FINALLY: always run this test, for cleaning after a scenario, broken or not
     - IGNORE: will ignore the test test result in the global testing result
    rudder_log can be:
     - APACHE: printing the apache access and error logs
     - WEBAPP: printing the latest webapp log
     - ALL   : printing all the logs described above
    """
    if not self.should_run(test, error_mode):
      return

    # prepare command
    datastate_file = "/tmp/datastate.json"
    with open(datastate_file, 'w+') as fp:
      json.dump(self.datastate, fp)
    env = 'DATASTATE=%s '%datastate_file
    if target != "localhost" and not target in self.datastate.keys():
      return
    env += 'TARGET_HOST=%s '%target
    env += 'TOKEN=%s '%(self.token)
    for k,v in kwargs.items():
      env += 'RUDDER_' + k + '=' + '"' + v + '" '
    if test.startswith("/"):
      testfile = test
      test = re.sub(r'.*/([\w\-]+)\.rb', r'\1', test)
    else:
      testfile = "spec/tests/" + test + ".rb"
    command = env + self.rspec + " " + testfile

    # run it
    now = datetime.now().isoformat()
    print("+%s"%command)
    process = Popen(command, shell=True)
    retcode = process.wait()

    self.__merge_reports()

    if retcode != 0:
      if error_mode != Err.IGNORE:
        self.errors = True
        if error_mode == Err.BREAK:
          self.stop = True
      if rudder_log is not None:
        self.dump_rudder_logs(target, rudder_log)
      return retcode
    else:
      return 0

  def dump_apache_logs(self):
    """ Print the rudder apache logs """
    print("Dumping the apache error logs:\n")
    dump_command = "tail -n 50 /var/log/rudder/apache2/error.log"
    (retcode, dump_process) = self.shell_on('server', dump_command, live_output=True)
    print("Dumping the apache access logs:\n")
    dump_command = "tail -n 50 /var/log/rudder/apache2/access.log"
    (retcode, dump_process) = self.shell_on('server', dump_command, live_output=True)

  def dump_webapp_logs(self):
    """ Print the rudder webapp logs """
    print("Dumping the webapp logs:\n")
    dump_command = "tail -n 100 /var/log/rudder/webapp/$(date +%Y_%m_%d.stderrout.log)"
    (retcode, dump_process) = self.shell_on('server', dump_command, live_output=True)

  def dump_all_logs(self):
    """ Print the rudder server logs """
    self.dump_webapp_logs
    self.dump_apache_logs

  def dump_rudder_logs(self, target, rudder_log):
    """ Print the given rudder logs, <rudder_log> is a RudderLog enum:
     - APACHE: printing the apache access and error logs
     - WEBAPP: printing the latest webapp log
     - ALL   : printing all the logs described above """

    switcher = {
      RudderLog.APACHE: self.dump_apache_logs,
      RudderLog.WEBAPP: self.dump_webapp_logs,
      RudderLog.ALL   : self.dump_all_logs
    }

    return switcher[rudder_log]()

  def run_retry_and_dump(self, target, test, retry, rudder_log, **kwargs):
    """ Run a test and retry it <retry> times if it fails
     if every retries fail, the given <rudder_log> will be dumped """
    for iTry in range(0, retry):
      if iTry == retry-1:
        result = self.run_and_dump(target, test, Err.BREAK, rudder_log, **kwargs)
      else:
        result = self.run(target, test, Err.IGNORE, **kwargs)
      if result == 0 :
        break
      sleep(10)

  def run_and_retry(self, target, test, retry, **kwargs):
    """ Run a test and retry it <retry> times if it fails """
    self.run_retry_and_dump(target, test, retry, None, **kwargs)

  def run_on(self, kind = "all", *args, **kwargs):
    """ Run a test on nodes of type kind """
    for host in self.nodes(kind):
      self.run(host, *args, **kwargs)

  def run_test_on(self, test_id, kind = "all", *args, **kwargs):
    """ Run a test on nodes of type kind """
    if test_id >= self.startTestNumber:
      print("EXECUTING TEST %d" %test_id)
      for host in self.nodes(kind):
          run(host, *args, **kwargs)
    else:
      print("SKIPPING TEST %d" %test_id)

  def shell_on(self, hostname, command, live_output=False):
    """ Run a shell command on a host and return its output without failing if there is an error """
    return self.test_shell_on(hostname, command, error_mode=Err.IGNORE, live_output=live_output)

  def shell(self, command, live_output=False):
    """ Run a shell command on localhost and return its output without failing if there is an error """
    return self.shell_on('localhost', command, live_output=live_output)

  def test_shell_on(self, hostname, command, error_mode=Err.CONTINUE, live_output=False):
    """
        Run a shell command on a host and return its output without failing if there is an error
        If the ret code is not zero, the test scenario will continue but will fail
        Error_mode can be :
         - CONTINUE: continue testing even if this fail, should be the default
         - BREAK: stop the scenario if this fail, for tests that change a state
         - IGNORE: will ignore the test test result in the global testing result
    """
    try:
      if live_output:
        print("+" + command)
      if hostname == 'localhost':
          return (0, check_output("LANG=C " + command, shell=True))
      else:
        if hostname not in self.datastate.keys():
          print("ERROR: No host named " + hostname)
          return (0, "")
        host = self.datastate[hostname]
        fail_exit = True if error_mode == Err.BREAK else False
        (returncode, output) = self.ssh_on(hostname, command)
        if returncode != 0:
          raise CalledProcessError(returncode, command, output)
        return (returncode, output)

    except CalledProcessError as e:
      print("ERROR(" + str(e.returncode) + ") in: " + command + " on " + hostname)
      if error_mode != Err.IGNORE:
        scenario.errors = True
      if error_mode == Err.BREAK:
        exit(1)
      return(e.returncode, e.output)


##### Do not care about what is below
def wait_for_generation(name, error_mode, server, date0, hostname, timeout=10):
  """ Wait for the generation of a given node promises """
  if not should_run(name, error_mode):
    return
  # wait for promise generation
  (retcode, agent_uuid) = shell(scenario.rcli + " nodes list | jq '.nodes | map(select(.hostname==\"" + hostname + "\" or .hostname ==\"" + hostname + ".rudder.local\")) | .[0].id'")
  agent_uuid = agent_uuid.rstrip().strip('"')
  if agent_uuid == "null":
    return
  time=0
  while True:
    time += 1
    if time >= timeout:
      break
    sleep(1)
    print("Waiting for " + agent_uuid + " rule generation")
    generated_old = "/var/rudder/share/" + agent_uuid + "/rules/cfengine-community/rudder_promises_generated"
    generated_new = "/var/rudder/share/" + agent_uuid + "/rules/cfengine-community/rudder-promises-generated"
    cmd = "cat " + generated_new + " " + generated_old + " 2>/dev/null | head -n1"
    (retcode, datestr) = shell_on(server, cmd)
    if datestr == "":
      continue
    if re.match(r'^\d+$', datestr):
      date = datestr
    else:
      (retcode, date) = shell("date -d " + datestr + " +%s")
    if int(date) > int(date0):
      break
  if time >= timeout:
    print("ERROR: Timeout in promise generation (>" + str(timeout) + "s)")


def host_date(name, error_mode, server):
  """ Return the current date on the host """
  if not should_run(name, error_mode):
    return None
  return shell_on(server, "date +%s")[1]


def get_param(param, default):
  if param in scenario.params:
    return scenario.params[param]
  else:
    return default

def _file_must_exist(filename):
  if not os.path.isfile(filename):
    print("ERROR: " + filename + " file doesn't exist")
    exit(1)

def get_tests():
  """ Return the list of techniques to be tested """
  tests = []
  tests_metadata = get_param("test", "").split(',')
  technique_root = get_param("root", "")
  for metadata_file in tests_metadata:
    _file_must_exist(metadata_file)
    with open(metadata_file) as fd:
      metadatas = json.load(fd)
      # metadata content : [ { test }, ... ]
      # test content : { "name": "test_name",
      #                  "inits": [ "inits command", ... ],  # it must be relative since the PATH will include the metadata file path
      #                  "directives": [ "directive_file", ... ],
      #                  "checks": [ "check_script.rb", ... ],
      #                  "sharedFiles": ["file to upload", ...],
      #                  "compliance": "expected compliance" }
      for metadata in metadatas:
        root = os.path.abspath(os.path.dirname(metadata_file))
        metadata['local_root'] = root
        metadata['remote_root'] = root.replace(technique_root,  "/var/rudder/configuration-repository/techniques/")

        # make directives path absolute
        directives = []
        for directive in metadata['directives']:
          path = root+'/'+directive
          _file_must_exist(path)
          directives.append(path)
        metadata['directives'] = directives

        # make checks path absolute
        checks = []
        for check in metadata['checks']:
          path = root+'/'+check
          _file_must_exist(path)
          checks.append(path)
        metadata['checks'] = checks

        # make inits path absolute
        inits = []
        for init in metadata['inits']:
          path = root+'/'+init
          _file_must_exist(path)
          inits.append(path)
        metadata['inits'] = inits

        # make sharedFiles path absolute
        sharedFiles = []
        for iFile in metadata['sharedFiles']:
          path = root+'/'+iFile
          _file_must_exist(path)
          sharedFiles.append(path)
        metadata['sharedFiles'] = sharedFiles

        tests.append(metadata)

  return tests

def extract_redmine_issue_infos(ticket_id):
  url="https://issues.rudder.io/issues/" + ticket_id + ".json"
  ret = requests.get(url, headers = {'Content-Type': 'application/json' })
  if ret.status_code == 200:
    return ret.json()
  else:
   print("Could not found the issue " + ticket_id)
   exit(1)

def get_issue_rudder_branch(issue):
  REDMINE_VERSION_DETECTOR = [ (r'master|.*~alpha\d+', r'master'), (r'4.2.0~prototype', r'prototype'), (r'(\d+\.\w\d*).*', r'\1') ]
  for k,v in REDMINE_VERSION_DETECTOR:
    if re.match(k, issue['issue']['fixed_version']['name']):
      return re.sub(k, v, issue['issue']['fixed_version']['name'])

def get_issue_rudder_version(issue):
  return re.sub(r'(\d+\.\w\d*).*', r'\1', issue['issue']['fixed_version']['name'])

def get_issue_pr(issue):
    custom_fields = issue['issue']['custom_fields']
    pr_counter = 0
    for iField in custom_fields:
      if iField['name'] == 'Pull Request' and iField['value'] != "":
        pr_url = iField['value']
        pr_counter += 1
    if pr_counter == 1:
      return pr_url

def setenv(client_path, url, token):
  """ Set environment variables for command calls """
  if client_path is not None:
    os.environ['PATH'] += ":" + client_path + "/cli"
    os.environ['PYTHONPATH'] = client_path +  "/lib.python"
  os.environ['RUDDER_SERVER'] = url
  os.environ['RUDDER_TOKEN'] = token
