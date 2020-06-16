#!/usr/bin/python3

# Sample file, to try to build a basic schema for platform inputs

import os
import json
import re
import sys
import traceback
from subprocess import Popen, PIPE
from jsonschema import validate, draft7_format_checker, Draft7Validator, RefResolver
import importlib

###################

# Datastate and Scneario_input are json file path
def run_scenario(name, datastate, scenario_input=None):
  try:
    # load and run
    parameters = {}
    module = importlib.import_module("scenarios." + name)

    scenario_to_run = getattr(module, name)
    if scenario_input is not None:
      with open(scenario_input) as f:
        data = json.load(f)
    else:
      data = None
    # Remove result.xml if any
    try:
      os.remove("result.xml")
    except OSError:
      pass
    # Sanity check the scenario on the platform
    s = scenario_to_run(name, datastate, scenario_input=data)
    s.execute()
    if s.errors:
      print("Test scenario '"+ name +"' failed on platform '" + name + "'")
      exit(5)
  except ValueError as e:
    print(e)
  except Exception:
    traceback.print_exc(file=sys.stdout)


###################

try:
  with open("data.json", "r") as json_file:
    jsonData = json.load(json_file)
except Exception as e:
    print("The data input seems malformed")
    print(e)
    exit(1)
#scenario = run_scenario("test_user", jsonData, "input.json")
#scenario = run_scenario("inventory", jsonData)
#scenario = run_scenario("b078d18e_7a99_4bd5_8386_43eaf4f3669f", jsonData)
scenario = run_scenario("cis", jsonData, "input.json")

