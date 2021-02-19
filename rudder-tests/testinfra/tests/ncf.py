import testinfra
import requests
import pytest
import json
import urllib3
urllib3.disable_warnings()


@pytest.fixture
def version(test_data):
  return test_data["version"]

@pytest.fixture
def agent_version(test_data):
  if "agent_version" in test_data:
    return test_data["agent_version"]
  else:
    return "ci/rudder-" + test_data["version"] + "-nightly"

@pytest.fixture
def pull_number(test_data):
  if "pull_number" in test_data:
    return test_data["pull_number"]
  else:
    return ""

"""
Run ncf tests from tag
"""
def ncf_from_tag(json_metadata, host, version, agent_version):
  with host.sudo():
    cmd = "/tmp/ncf-setup test-local https://github.com/Normation/ncf.git#branches/rudder/" + version + " " + agent_version + " --testinfra"
    ret = host.run(cmd)
    json_metadata["commands"].append({"cmd": cmd, "output": ret.stdout, "stderr": ret.stderr, "exit_code": ret.rc})
    assert ret.succeeded

"""
Run ncf tests from pr
"""
def ncf_from_pr(json_metadata, host, version, agent_version, pull_number):
  with host.sudo():
    cmd = "/tmp/ncf-setup test-pr https://github.com/Normation/ncf.git#branches/rudder/" + version + " " + agent_version + " " +  pull_number + " --testinfra"
    ret = host.run(cmd)
    json_metadata["commands"].append({"cmd": cmd, "output": ret.stdout, "stderr": ret.stderr, "exit_code": ret.rc})
    assert ret.succeeded

"""
Main test
"""
def test_ncf(json_metadata, host, version, agent_version, pull_number, token, webapp_url):
  if "commands" not in json_metadata:
    json_metadata["commands"] = []
  if not pull_number:
    ncf_from_tag(json_metadata, host, version, agent_version)
  else:
    ncf_from_pr(json_metadata, host, version, agent_version, pull_number)

