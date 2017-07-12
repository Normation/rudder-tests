#!/usr/bin/env python

import re
import copy
import os
import json
from subprocess import Popen, check_output, PIPE, CalledProcessError
from time import sleep
from datetime import datetime
from pprint import pprint

class Scenario:
  """ Holds a scenario data 
  Most scenario related methods are global and not in this class to make scenario writing look like script writing
  """
  def __init__(self, platform, rspec, rcli, frmt, run_only, run_finally, err_stop, params):
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
Err = enum('CONTINUE', 'BREAK', 'FINALLY')


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

def run(target, test, error_mode, **kwargs):
  """ Run one test in a scenario 
  error_mode can be : 
   - CONTINUE: continue testing even if this fail, should be the default
   - BREAK: stop the scenario if this fail, for tests that change a state
   - FINALLY: always run this test, for cleaning after a scenario, broken or not
  """
  if not should_run(test, error_mode):
    return

  # prepare command
  if target == 'localhost':
    env = 'TARGET_HOST=localhost '
  else:
    env = 'TARGET_HOST=' + scenario.pf + '_' + target + ' '
    # add version
    (major, minor) = scenario.host_rudder_version(target)
    env += 'RUDDER_AGENT_VERSION_MAJOR="' + major +'" '
    env += 'RUDDER_AGENT_VERSION_MINOR="' + minor +'" '
  for k,v in kwargs.items():
    env += 'RUDDER_' + k + '=' + '"' + v + '" '
  if test.startswith("/"):
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
    scenario.errors = True
    if error_mode == Err.BREAK:
      scenario.stop = True


def run_on(kind = "all", *args, **kwargs):
  """ Run a test on nodes of type kind """
  for host in scenario.nodes(kind):
    run(host, *args, **kwargs)

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


def shell_on(hostname, command):
  """ Run a shell command on a host and return its output without failing if there is an error """
  try:
    if hostname == 'localhost':
      return check_output("LANG=C " + command, shell=True)
    else:
      if hostname not in scenario.platform.hosts:
        print("ERROR: No host named " + hostname)
        return ""
      host = scenario.platform.hosts[hostname]
      return host.run(command)
  except CalledProcessError, e:
    print("ERROR(" + str(e.returncode) + ") in: " + command + " on " + hostname)
    return e.output


def shell(command):
  """ Run a shell command on localhost and return its output without failing if there is an error """
  return shell_on('localhost', command)


def wait_for_generation(name, error_mode, server, date0, hostname, timeout=10):
  """ Wait for the generation of a given node promises """
  if not should_run(name, error_mode):
    return
  # wait for promise generation
  agent_uuid = shell(scenario.rcli + " nodes list | jq '.nodes | map(select(.hostname==\"" + hostname + "\")) | .[0].id'")
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
    datestr = shell_on(server, cmd)
    if datestr == "":
      continue
    if re.match(r'^\d+$', datestr):
      date = datestr
    else:
      date = shell("date -d " + datestr + " +%s")
    if int(date) > int(date0):
      break
  if time >= timeout:
    print("ERROR: Timeout in promise generation (>" + str(timeout) + "s)")


def host_date(name, error_mode, server):
  """ Return the current date on the host """
  if not should_run(name, error_mode):
    return None
  return shell_on(server, "date +%s")


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
