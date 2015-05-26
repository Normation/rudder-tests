#!/usr/bin/python

import re
import copy
from subprocess import Popen, check_output, PIPE, CalledProcessError
from time import sleep
from datetime import datetime
from pprint import pprint

class Scenario:
  """ Holds a scenario data 
  Most scenario related methods are global and not in this class to make scenario writing look like script writing
  """
  def __init__(self, platform, rspec, rcli, frmt, run_only, run_finally, err_stop):
    self.errors = False
    self.platform = platform
    self.pf = platform.name
    self.rspec = rspec
    self.rcli = rcli
    self.frmt = frmt
    self.run_only = run_only
    self.run_finally = run_finally
    self.err_stop = err_stop

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


# Global variable that hold current scenario data
scenario = None

def enum(*sequential, **named):
  """ Enum compatibility for old python versions """
  enums = dict(zip(sequential, range(len(sequential))), **named)
  return type('Enum', (), enums)

# Error handling mode in scenario
Err = enum('CONTINUE', 'BREAK', 'FINALLY')


def dont_run(test, mode):
  """ Return True when the test must not be run """
  # Beware, negative logic
  if scenario.err_stop and scenario.errors:   # stop everything after error if 'err_stop'
    return True
  if mode != Err.FINALLY and scenario.errors: # stop everything not Finally after errors
    return True
  if scenario.run_only is not None:           # do not run filtered out tests
    if test not in scenario.run_only:
      return True
  if mode == Err.FINALLY and not scenario.run_finally: # do not run finally unless 'run_finally'
    return True
  return False


############################################
# Commands to be used in a scenario script #
############################################

def run(target, test, error_mode, **kwargs):
  """ Run one test in a scenario 
  error_mode can be : 
   - CONTINUE: continue testing even if this fail, should be the default
   - BREAK: stop the scenario if this fail, for tests that change a state
   - FINALLY: always run this test, for leaning after a scenario, broken or not
  """
  if dont_run(test, error_mode):
    return

  # prepare command
  if target == 'localhost':
    env = 'TARGET_HOST=localhost '
  else:
    env = 'TARGET_HOST=' + scenario.pf + '_' + target + ' '
  for k,v in kwargs.items():
    env += 'RUDDER_' + k + '=' + '"' + v + '" '
  command = env + scenario.rspec + " spec/tests/" + test + ".rb"

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

  if retcode != 0 and (error_mode == Err.BREAK or scenario.err_stop):
    scenario.errors = True


def run_on(kind = "all", *args, **kwargs):
  """ Run a test on nodes of type kind """
  for host in scenario.nodes(kind):
    run(host, *args, **kwargs)

def start():
  """ Start a scenario """
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
  if dont_run(name, error_mode):
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
    datestr = shell_on(server, "cat /var/rudder/share/" + agent_uuid + "/rules/cfengine-community/rudder_promises_generated 2>/dev/null")
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
  if dont_run(name, error_mode):
    return None
  return shell_on(server, "date +%s")


