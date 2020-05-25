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

def run_scenario(name, datastate, json_file=None):
  try:
    # load and run
    parameters = {}
    module = importlib.import_module("scenario." + name)

    scenario_to_run = getattr(module, "Scenario")
    if json_file is not None:
      with open(json_file) as f:
        data = json.load(f)
    else:
      data = None
      import os
    # Remove result.xml if any
    try:
      os.remove("result.xml")
    except OSError:
      pass
    # Sanity check the scenario on the platform
    s = scenario_to_run(name, datastate)
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
scenario = run_scenario("b078d18e-7a99-4bd5-8386-43eaf4f3669f", jsonData)
