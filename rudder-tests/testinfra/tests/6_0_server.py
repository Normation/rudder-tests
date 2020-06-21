import testinfra
import requests
import pytest
import json
import urllib3
urllib3.disable_warnings()


"""
Check users and group
"""
def rudder_groups(host):
    # Webapp
    assert host.group("rudder-slapd").exists
    assert host.group("ncf-api-venv").exists
    assert host.group("rudder").exists

def rudder_users(host):
    # Webapp
    assert host.user("rudder-slapd").exists
    assert host.user("ncf-api-venv").exists

def rudder_perms(host):
    # Webapp
    slapd_conf = host.file("/opt/rudder/etc/openldap/slapd.conf")
    assert slapd_conf.user == "root"
    assert slapd_conf.group == "rudder-slapd"
    assert slapd_conf.mode == 0o640

    ldap_dir = host.file("/var/rudder/ldap")
    assert ldap_dir.user == "rudder-slapd"
    assert ldap_dir.group == "rudder-slapd"

    ncf_api_venv = host.file("/var/lib/ncf-api-venv")
    assert ncf_api_venv.user == "ncf-api-venv"
    assert ncf_api_venv.group == "ncf-api-venv"

    assert host.file("/var/rudder/inventories").mode == 0o751

    ## configuration-repository group owner
    cmd = host.run("find /var/rudder/configuration-repository ! -group rudder")
    assert cmd.stdout.strip() == ""

    ## git files
    cmd = host.run("find /var/rudder/configuration-repository/.git ! -perm -u=rw")
    assert cmd.stdout.strip() == ""
    cmd = host.run("find /var/rudder/configuration-repository/.git ! -perm -g=rw")
    assert cmd.stdout.strip() == ""

    ## technique files
    cmd = host.run("find /var/rudder/configuration-repository/techniques ! -perm -u=rw")
    assert cmd.stdout.strip() == ""
    cmd = host.run("find /var/rudder/configuration-repository/techniques ! -perm -g=rw")
    assert cmd.stdout.strip() == ""

    ## Secure files
    secure_files = [
                     "/opt/rudder/etc/rudder-web.properties",
                     host.run("/usr/bin/getent passwd root | cut -d: -f6").stdout.strip() + "/.pgpass",
                     "/opt/rudder/etc/rudder-users.xml",
                     "/opt/rudder/etc/rudder-passwords.conf"
                   ]
    for f in secure_files:
      assert host.file(f).user == "root", "Non compliant file was %s"%f
      assert host.file(f).group == "root", "Non compliant file was %s"%f
      assert host.file(f).mode == 0o600, "Non compliant file was %s"%f

    ## Network files
    network_files = [
                      "/opt/rudder/etc/rudder-networks-24.conf",
                      "/opt/rudder/etc/rudder-networks-policy-server-24.conf"
                    ]

    for f in network_files:
      assert host.file(f).user == "root", "Non compliant file was %s"%f
      assert host.file(f).group == "root", "Non compliant file was %s"%f
      assert host.file(f).mode == 0o600, "Non compliant file was %s"%f


def rudder_services(host):
    # Webapp
    assert host.service("rudder-jetty").is_enabled
    assert host.service("rudder-jetty").is_running
    assert host.service("rudder-slapd").is_enabled
    if host.system_info.distribution == "centos":
      assert host.service("httpd").is_running
    else:
      assert host.service("apache2").is_running


"""
Main test
"""
def test_server_perms(host, token, webapp_url):
  with host.sudo():
    rudder_groups(host)
    rudder_users(host)
    rudder_perms(host)
    rudder_services(host)

