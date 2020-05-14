#!/usr/bin/python3
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
    os.remove("result.xml")
    s = scenario_to_run(name, datastate)
    s.execute()

    if s.errors:
      print("Test scenario '"+ name +"' failed on platform '" + name + "'")
      exit(5)
  except:
    traceback.print_exc(file=sys.stdout)


###################

schema = {
  # SSH client minimal infos
  "ssh": {
    "type": "object",
    "properties": {
      "ssh_cred": { "type": "string" },
      "ssh_user": { "type": "string" },
      "ssh_port": { "type": "integer", "minimum": 1, "maximum": 65535},
          "role": { "type": "string"},
    },
    # role is not required, just nice to have
    "required": ["ip", "ssh_cred", "ssh_user", "ssh_port"],
  },
  # Basic host definition
  "host": {
    "allOf": [
        { "properties":
            {
              "ip": { "format": "ipv4" },
            },
           "required": ["ip"],
        },
        { "$ref": "#ssh" }
    ]
  },

  # Rudder server definition
  "rudder_server": {
    "allOf": [
      { "properties":
          {
            "webapp_url": {
              "type": "string",
              "format": "uri",
              "pattern": "^https://"
            }
          },
        "required": ["webapp_url"],
      },
      { "$ref": "#host" },
      { "required": ["role"] }
    ]
  },
}

input_schema = {
  # Expected schema
  "type": "object",

  "properties": {
    "server": { "$ref": "#rudder_server" },
    "agent": { "$ref": "#host" },
  },
  "required": ["server"],
  "additionalProperties": False
}

def validateJson(jsonData):
    try:
        resolver = RefResolver.from_schema(schema)
        validate(instance=jsonData, schema=input_schema, format_checker=draft7_format_checker, resolver=resolver)
    except Exception as err:
        print(err)
        return False
    return True


data = '''
{ "server": {
    "ip": "127.0.0.1",
    "role": "server",
    "ssh_cred": "path to my key",
    "ssh_port": 2222,
    "ssh_user": "vagrant",
    "webapp_url": "https://localhost:8281/rudder"
  }
}'''

jsonData = json.loads(data)
isValid = validateJson(jsonData)
if isValid:
    print(jsonData)
    print("Given JSON data is Valid")
    scenario = run_scenario("b078d18e-7a99-4bd5-8386-43eaf4f3669f", jsonData)
