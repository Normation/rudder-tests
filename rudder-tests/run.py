#!/usr/bin/python3
"""
Rudder test framework

Usage:
    rtf run <scenario> [--data=<datastate_file>] [--input=<input_file>]

Options:
    --data <datastate_file> Datastate json file describing the target infrastucture to run the scenario on
    --input <input_file> Input json file to fill scenario optional parameters

Commands:
    run
       Run the given scenario on the target machines
"""

# Sample file, to try to build a basic schema for platform inputs

import os
import json
import re
import sys
import traceback
from subprocess import Popen, PIPE
from docopt import docopt
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
## MAIN
if __name__ == "__main__":
  input_file = "input.json"
  data_file = "data.json"
  args = docopt(__doc__)
  if args['--input']:
    input_file = args["--input"]
  if args['--data']:
    data_file = args["--data"]

  try:
    with open("data.json", "r") as json_file:
      jsonData = json.load(json_file)
  except Exception as e:
      print("The data input seems malformed")
      print(e)
      exit(1)
  scenario = run_scenario(args['<scenario>'], jsonData, "input.json")

