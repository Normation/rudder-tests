#!/usr/bin/env python

import re
import copy
import os
import json
import requests
import traceback
from subprocess import Popen, check_output, PIPE, CalledProcessError
from time import sleep
from datetime import datetime
from pprint import pprint

class Scenario:
  """ Holds a scenario data
  Most scenario related methods are global and not in this class to make scenario writing look like script writing
  """
  def __init__(self, platform, rspec, rcli, frmt, run_only, run_finally, err_stop, params, startTestNumber):
    self.stop = False
    self.errors = False
    self.platform = platform
    self.pf = platform.name
    self.rspec = rspec
    self.rcli = rcli
    self.frmt = frmt
    self.run_only = run_only
    self.run_finally = run_finally
    self.err_stop = err_stop
    self.params = params
    self.startTestNumber = startTestNumber

  def nodes(self, kind = "all"):
    # kind not defined, return all nodes
    if (kind == "all"):
      return self.platform.hosts.keys()
    else:
      nodes = []
      for hostname, host in self.platform.hosts.items():
        if host.info['rudder-setup'] == kind:
          nodes.append(hostname)
      return nodes

  def host_rudder_version(self, hostname):
    host = self.platform.hosts[hostname]
    version_line = host.cached_run("rudder agent version", fail_exit=False)
    match = re.match(r'^Rudder agent (\d+)\.(\d+)\..*', version_line)
    if match:
      return (match.group(1), match.group(2))
    else:
      return ("", "")

  def server_rudder_version(self):
    servers = scenario.nodes("server")
    # assume a single server
    if len(servers) != 1:
      return ""
    (major, minor) = self.host_rudder_version(servers[0])
    return major+"."+minor

# Global variable that hold current scenario data
scenario = None

def enum(*sequential, **named):
  """ Enum compatibility for old python versions """
  enums = dict(zip(sequential, range(len(sequential))), **named)
  return type('Enum', (), enums)

# Error handling mode in scenario
Err = enum('CONTINUE', 'BREAK', 'FINALLY', 'IGNORE')
RudderLog = enum('APACHE', 'WEBAPP', 'ALL')

# This method is used to prevent running new test in cases of error
# If there's been error in scenario, then only the test with Err.FINALLY must be run
def should_run(test, mode):
  """ Return True when the test must be ran """
  if not scenario.stop:
    return True

  if mode != Err.FINALLY:
    return False
  else: # mode == Err.FINALLY
    return scenario.run_finally


############################################
# Commands to be used in a scenario script #
############################################

# Run a test
# If the test starts with a /, then the full path of the test will be used,
# otherwise it will look for a ruby script in specs/tests directory
def run(target, test, error_mode, **kwargs):
  """ Run one test in a scenario without any log dump """
  return run_and_dump(target, test, error_mode, None, **kwargs)

def run_and_dump(target, test, error_mode, rudder_log, **kwargs):
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
  if not should_run(test, error_mode):
    return

  # prepare command
  if target == 'localhost':
    env = 'TARGET_HOST=localhost '
  else:
    if not target in scenario.platform.hosts:
      return
    env = 'TARGET_HOST=' + scenario.pf + '_' + target + ' '
    # add version
    (major, minor) = scenario.host_rudder_version(target)
    env += 'RUDDER_AGENT_VERSION_MAJOR="' + major +'" '
    env += 'RUDDER_AGENT_VERSION_MINOR="' + minor +'" '
  for k,v in kwargs.items():
    env += 'RUDDER_' + k + '=' + '"' + v + '" '
  if test.startswith("/"):
    env += 'SCENARIO_BASE="' + os.path.dirname(test) + '" '
    testfile = test
    test = re.sub(r'.*/([\w\-]+)\.rb', r'\1', test)
  else:
    testfile = "spec/tests/" + test + ".rb"
  command = env + scenario.rspec + " " + testfile

  # run it
  now = datetime.now().isoformat()
  if scenario.frmt == "documentation":
    print("[" + now + "] Running '" + test + "' test on " + target)
    print(command)
  process = Popen(command, shell=True)
  retcode = process.wait()

  # separator
  if scenario.frmt == "json":
    print(",")
  else:
    print("")

  if retcode != 0:
    if error_mode != Err.IGNORE:
      scenario.errors = True
      if error_mode == Err.BREAK:
        scenario.stop = True
    if rudder_log is not None:
      dump_rudder_logs(target, rudder_log)
    return retcode
  else:
    return 0

def dump_apache_logs():
  """ Print the rudder apache logs """
  print("Dumping the apache error logs:\n")
  dump_command = "tail -n 50 /var/log/rudder/apache2/error.log"
  (retcode, dump_process) = shell_on('server', dump_command, live_output=True)
  print("Dumping the apache access logs:\n")
  dump_command = "tail -n 50 /var/log/rudder/apache2/access.log"
  (retcode, dump_process) = shell_on('server', dump_command, live_output=True)

def dump_webapp_logs():
  """ Print the rudder webapp logs """
  print("Dumping the webapp logs:\n")
  dump_command = "tail -n 100 /var/log/rudder/webapp/$(date +%Y_%m_%d.stderrout.log)"
  (retcode, dump_process) = shell_on('server', dump_command, live_output=True)

def dump_all_logs():
  """ Print the rudder server logs """
  dump_webapp_logs
  dump_apache_logs

def dump_rudder_logs(target, rudder_log):
  """ Print the given rudder logs, <rudder_log> is a RudderLog enum:
   - APACHE: printing the apache access and error logs
   - WEBAPP: printing the latest webapp log
   - ALL   : printing all the logs described above """

  switcher = {
    RudderLog.APACHE: dump_apache_logs,
    RudderLog.WEBAPP: dump_webapp_logs,
    RudderLog.ALL   : dump_all_logs
  }

  return switcher[rudder_log]()

def run_retry_and_dump(target, test, retry, rudder_log, **kwargs):
  """ Run a test and retry it <retry> times if it fails
   if every retries fail, the given <rudder_log> will be dumped """
  for iTry in range(0, retry):
    if iTry == retry-1:
      result = run_and_dump(target, test, Err.BREAK, rudder_log, **kwargs)
    else:
      result = run(target, test, Err.IGNORE, **kwargs)
    if result == 0 :
      break
    sleep(10)

def run_and_retry(target, test, retry, **kwargs):
  """ Run a test and retry it <retry> times if it fails """
  run_retry_and_dump(target, test, retry, None, **kwargs)

def run_on(kind = "all", *args, **kwargs):
  """ Run a test on nodes of type kind """
  for host in scenario.nodes(kind):
    run(host, *args, **kwargs)

def run_test_on(test_id, kind = "all", *args, **kwargs):
  """ Run a test on nodes of type kind """
  if  test_id >= scenario.startTestNumber:
    print("EXECUTING TEST %d" %test_id)
    for host in scenario.nodes(kind):
        run(host, *args, **kwargs)
  else:
    print("SKIPPING TEST %d" %test_id)

def start(doc):
  """ Start a scenario """
  # Do not start if the scenario is not properly loaded
  if scenario is None:
    raise ValueError(doc) # way to stop a scenario, this should be catched by the loader
  now = datetime.now().isoformat()
  print("[" + now + "] Begining of scenario")


def finish():
  """ Finish a scenario """
  now = datetime.now().isoformat()
  print("[" + now + "] End of scenario")


def shell_on(hostname, command, live_output=False):
  """ Run a shell command on a host and return its output without failing if there is an error """
  return test_shell_on(hostname, command, error_mode=Err.IGNORE, live_output=live_output)

def shell(command, live_output=False):
  """ Run a shell command on localhost and return its output without failing if there is an error """
  return shell_on('localhost', command, live_output=live_output)

def test_shell_on(hostname, command, error_mode=Err.CONTINUE, live_output=False):
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
      if hostname not in scenario.platform.hosts:
        print("ERROR: No host named " + hostname)
        return (0, "")
      host = scenario.platform.hosts[hostname]
      fail_exit = True if error_mode == Err.BREAK else False
      (returncode, output) = host.run_with_ret_code(command, fail_exit=fail_exit, live_output=live_output)
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
    if re.match(r'^\d+\s*$', datestr):
        date = datestr[0:10]
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
