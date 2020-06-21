import testinfra
import requests
import pytest
import json
import urllib3
urllib3.disable_warnings()

def get_apache_user(host):
    if host.system_info.distribution == "centos":
      return "apache"
    return "www-data"

"""
Check users and group
"""
def rudder_groups(host):
    assert host.group("rudder-policy-reader").exists
    assert host.group("rudder").exists

def rudder_users(host, apache_user):
    assert "rudder-policy-reader" in host.user(apache_user).groups
    assert host.user("rudder-relayd").exists
    assert host.user("rudder").exists

def rudder_perms(host, apache_user):
    policy_folder = host.file("/var/rudder/share")
    assert policy_folder.group == "rudder-policy-reader"
    assert policy_folder.mode == 0o2755

    shared_files = host.file("/var/rudder/shared-files")
    assert shared_files.user == "rudder-relayd"
    assert shared_files.group == "rudder"
    assert shared_files.mode == 0o770

    shared_files2 = host.file("/var/rudder/configuration-repository/shared-files")
    assert shared_files.user == "root"
    assert shared_files.group == "rudder"
    assert shared_files.mode == 0o750

    shared_files = host.file("/var/rudder/inventories")
    assert shared_files.mode == 0o755

    ## Conf files
    cmd = host.run("find /opt/rudder/etc/relayd ! -group rudder")
    assert cmd.stdout.strip() == ""
    assert host.file("/opt/rudder/etc/relayd").mode == 0o750
    assert host.file("/opt/rudder/etc/relayd/main.conf").mode == 0o640
    assert host.file("/opt/rudder/etc/relayd/logging.conf").mode == 0o640

    ## Inventory folders
    inventory_folders = [
                         "/var/rudder/inventories/incoming",
                         "/var/rudder/inventories/failed",
                         "/var/rudder/inventories/accepted-nodes-updates",
                         "/var/rudder/reports/incoming",
                         "/var/rudder/reports/failed",
                        ]

    for f in inventory_folders:
        assert host.file(f).user == apache_user, "Non compliant file was %s"%f
        assert host.file(f).group == "rudder", "Non compliant file was %s"%f
        assert host.file(f).mode == 0o770, "Non compliant file was %s"%f


    ## SSL files
    assert host.file("/opt/rudder/etc/ssl/rudder.key").group == apache_user
    assert host.file("/opt/rudder/etc/ssl/rudder.key").mode == 0o640


def rudder_services(host):
    # Webapp
    assert host.service("rudder-relayd").is_running
    assert host.service("rudder-relayd").is_enabled
    if host.system_info.distribution == "centos":
      assert host.service("httpd").is_running
      assert host.service("httpd").is_enabled
    else:
      assert host.service("apache2").is_running
      assert host.service("apache2").is_enabled


"""
Main test
"""
def test_relay_perms(host, token, webapp_url):
  apache_user = get_apache_user(host)
  with host.sudo():
    rudder_groups(host)
    rudder_users(host, apache_user)
    rudder_perms(host, apache_user)
    rudder_services(host)

