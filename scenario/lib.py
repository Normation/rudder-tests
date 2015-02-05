#!/usr/bin/python

import os
import re
from subprocess import Popen, check_output, PIPE
from time import sleep
from datetime import datetime
from pprint import pprint

class Scenario:
  def __init__(self, platform, rspec, rcli, server_name, frmt = "documentation", run_only=None):
    self.errors = False
    self.pf = platform
    self.rspec = rspec
    self.rcli = rcli
    self.server_name = server_name
    self.frmt = frmt
    self.run_only = run_only

scenario = None

def enum(*sequential, **named):
  enums = dict(zip(sequential, range(len(sequential))), **named)
  return type('Enum', (), enums)

Err = enum('CONTINUE', 'BREAK', 'FINALLY')


# Beware, reverse logic
def dont_run(name, mode):
  if mode != Err.FINALLY and scenario.errors:
    return True
  if scenario.run_only is not None:
    if name not in scenario.run_only:
      return True
  return False


# run one test
# error_mode can be : 
#  - CONTINUE: continue testing even if this fail, should ne the default
#  - BREAK: stop the scenario if this fail, for tests that change a state
#  - FINALLY: always run this test, for leaning after a scenario, broken or not
def run(target, test, error_mode, **kwargs):
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

  if retcode != 0 and error_mode == Err.BREAK:
    errors = True


def finish():
  now = datetime.now().isoformat()
  print("[" + now + "] End of scenario")


def shell(command):
  process = Popen(command, stdout=PIPE, shell=True)
  output, unused_err = process.communicate()
  scenario.retcode = process.poll()
  if scenario.retcode != 0:
    print("ERROR(" + str(scenario.retcode) + ") in: " +command)
  return output


def env(client_path, url, token):
  os.environ['PATH'] += ":" + client_path + "/cli"
  os.environ['PYTHONPATH'] = client_path +  "/lib.python"
  os.environ['RUDDER_SERVER'] = url
  os.environ['RUDDER_TOKEN'] = token


def wait_for_generation(name, error_mode, date0, hostname, timeout=10):
  if dont_run(name, error_mode):
    return
  # wait for promise generation
  agent_uuid = shell(scenario.rcli + " nodes list | jq '.nodes | map(select(.hostname==\"" + hostname + "\")) | .[0].id'")
  agent_uuid = agent_uuid.rstrip().strip('"')
  if agent_uuid == "null":
    return
  time=0
  while True:
    sleep(1)
    print("Waiting for " + agent_uuid + " rule generation")
    datestr = shell("vagrant ssh " + scenario.server_name + " -c 'sudo cat /var/rudder/share/" + agent_uuid + "/rules/cfengine-community/rudder_promises_generated 2>/dev/null' 2>/dev/null")
    datestr = datestr.rstrip()
    if datestr == "":
      continue
    if re.match(r'^\d+$', datestr):
      date = datestr
    else:
      date = shell("date -d " + datestr + " +%s")
    if int(date) > int(date0):
      break
    time += 1
    if time >= timeout:
      break
  if time >= timeout:
    print("ERROR: Timeout in promise generation (>" + str(timeout) + "s)")


def server_date(name, error_mode):
  if dont_run(name, error_mode):
    return None
  return shell("vagrant ssh " + scenario.server_name + " -c 'date +%s' 2>/dev/null").strip()


