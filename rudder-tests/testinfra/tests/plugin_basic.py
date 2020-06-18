import testinfra
import json
import re
import pytest

@pytest.fixture
def rpkg_path(test_data):
    return test_data["plugin_path"]
@pytest.fixture
def rpkg_name(test_data):
    return test_data["plugin_name"]
@pytest.fixture
def rpkg_version(test_data):
    return test_data["plugin_version"]

"""
Test ar archive
"""
def test_rpkg(host, rpkg_path, rpkg_name, rpkg_version):
  cmd1 = host.run("ar -t \"%s\""%rpkg_path)
  lines = [ line for line in cmd1.stdout.strip().split("\n") if line ]
  assert cmd1.succeeded
  assert "metadata" in lines
  assert "scripts.txz" in lines
  for line in lines:
    pattern = re.compile(r"^(metadata|.*\.txz)$")
    assert pattern.match(line)


"""
Test the metadata
"""
def test_metadata(host, rpkg_path, rpkg_name, rpkg_version):
  cmd = host.run("ar -p \"%s\" metadata"%rpkg_path)
  data = json.loads(cmd.stdout)
  assert cmd.succeeded

  # Test the content part of the metadata
  assert set(["type", "name", "version"]).issubset(set(data.keys()))
  assert data["type"] == "plugin"
  if rpkg_name:
    assert data["name"] == "rudder-plugin-%s"%rpkg_name
  if rpkg_version:
    version_pattern = re.compile(r"^\d+\.\d+-\d+\.\d+(-nightly)?$")
    assert version_pattern.match(data["version"])
    assert data["version"] == rpkg_version

  # Tests that all archive in the rpkg are listed in its metadata
  lines = host.run("ar -t \"%s\""%rpkg_path).stdout.split("\n")
  assert list(data["content"].keys()) == [ line for line in lines if line.endswith(".txz") and line != "scripts.txz" ]
