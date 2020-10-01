import re
import testinfra
import pytest

# test_path
@pytest.fixture
def test_path(test_data):
    return test_data["test_path"]

def read_pester_result(output):
  reg = re.compile(r".*Tests Passed: (?P<passed>[0-9]+), Failed: (?P<failed>[0-9]+), Skipped: (?P<skipped>[0-9]+), Pending: (?P<pending>[0-9]+), Inconclusive: (?P<inconclusive>[0-9]+).*")
  m = reg.search(output)
  return { "passed": int(m.group('passed')),
           "failed": int(m.group('failed')),
           "skipped": int(m.group('skipped')),
           "pending": int(m.group('pending')),
           "inconclusive": int(m.group('inconclusive'))
         }

"""
Main test
"""
def test_ncf(json_metadata, host, token, webapp_url, test_path):
  if "commands" not in json_metadata:
    json_metadata["commands"] = []
  if test_path != "all":
    cmd = "rudder agent tests -TestFile '%s'"%test_path
  else:
    cmd = "rudder agent tests"
  ret = host.run(cmd)
  json_metadata["commands"].append({"cmd": cmd, "output": ret.stdout, "exit_code": ret.rc})
  print(ret.stdout)

  # For some reasons ssh on powershell always return 0
  result = read_pester_result(ret.stdout)
  assert result["failed"] == 0 and result["passed"] > 0


