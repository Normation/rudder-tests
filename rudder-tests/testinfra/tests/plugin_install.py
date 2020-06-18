import testinfra
import requests
import pytest
import json
import urllib3
urllib3.disable_warnings()


# rpkg_path on the node side
@pytest.fixture
def rpkg_path(test_data):
    return test_data["plugin_path"]


"""
Check rudder-jetty status
"""
def jetty_status(host, token, webapp_url):
    assert host.service("rudder-jetty").is_enabled
    assert host.service("rudder-jetty").is_running

    headers = {"X-API-TOKEN": token}
    response = requests.get(webapp_url + "/api/latest/system/status", headers=headers, verify=False)
    assert response.status_code == 200
    assert json.loads(response.text)["data"]["global"] == "OK"

"""
Main test
"""
def test_plugin_install(host, rpkg_path, token, webapp_url):
  jetty_status(host, token, webapp_url)
  with host.sudo():
    cmd = host.run("rudder package install-file " + rpkg_path)
    assert cmd.succeeded
  jetty_status(host, token, webapp_url)
