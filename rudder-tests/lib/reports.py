from lxml import etree
import json

class XMLReport:
  def __init__(self, path, workspace):
    self.path = path
    self.workspace = workspace

  """
    Each serverspec call (== each call to a test) will produce a report xml file.
    We need to merge them at runtime, and hierachize the report per scenario
  """
  def merge_reports(self, name, new_report=None):
    if new_report is None:
      new_report=self.workspace + "/serverspec-result.xml"
    try:
      single_tree = etree.parse(new_report)
      try:
        global_tree = etree.parse(self.path)
      except:
        global_tree = etree.ElementTree(etree.Element("testsuites", name=name))

      for element in single_tree.getroot().findall("testsuite"):
        global_tree.getroot().append(element)

      with open(self.path, 'wb+') as f:
        f.write(etree.tostring(global_tree))
    except:
      # dump partial report content in case of error
      try:
        with open(new_report, 'r') as fin:
          print(fin.read())
      except Exception as e:
          print(e)

class JSONReport:
  def __init__(self, path, workspace):
    self.path = path
    self.workspace = workspace

  """
    Each testinfra test call (== each call to a test != scenario) will produce a report json file.
    We need to merge them at runtime, and hierachize the report per scenario
    Resulting json should follow the format:
    {
      "scenarios": [
                     {
                       "datastate": {},
                       "summary": {},
                       "name": "xxxx",
                       "tests": [
                                  { "input_data": "",
                                    "summary": {},
                                    ...
                                  },
                                ]
                     },
                   ]
    }
  """
  def merge_reports(self, name, new_report=None, input_data={}, datastate={}, scenario_input={}):
    if new_report is None:
      new_report=self.workspace + "/serverspec-result.xml"
    try:
      with open(self.path) as main_json:
        main_data = json.load(main_json)
    except:
        main_data = { "datastate": datastate,
                      "scenario_input": scenario_input,
                      "summary": { "passed": 0, "failed": 0, "total": 0, "collected": 0 },
                      "scenarios": [
                        { "name": name,
                          "tests": []
                        }
                      ]
                    }
    with open(new_report, 'r') as new_json:
      new_data = json.load(new_json)
      new_data["input_data"] = input_data

    # Look for the targetted scenario
    for s in main_data["scenarios"]:
      if s["name"] == name:
        # Add current test infos
        s["tests"].append(new_data)

    # Update the scenario summary
    main_data["summary"]["total"] += new_data["summary"]["total"]
    if "passed" in new_data["summary"]:
      main_data["summary"]["passed"] += new_data["summary"]["passed"]
    if "failed" in new_data["summary"]:
      main_data["summary"]["failed"] += new_data["summary"]["failed"]
    main_data["summary"]["collected"] += new_data["summary"]["collected"]

    with open(self.path, 'w+') as outfile:
      json.dump(main_data, outfile)
