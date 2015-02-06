#!/usr/bin/python

import scenario.lib
from subprocess import Popen, check_output, PIPE


if __name__ == "__main__":
  port = "8381"
  platform = "centos"
  run_only=None
  # available: progress, documentation, html, json
  frmt = "documentation"
  client_path = "/home/bpeccatte/Rudder/rudder-api-client"
  rudder_url = "https://localhost:" + port + "/rudder"
  server_name = platform + "_server"
  rspec_bin = "/usr/bin/ruby2.1 -S rspec"
  rspec_opts = "--order defined --fail-fast --format " + frmt
  rspec = rspec_bin + ' ' + rspec_opts
  command = "vagrant ssh " + server_name + " -c 'sudo cat /root/rudder-token' 2>/dev/null"
  process = Popen(command, stdout=PIPE, shell=True)
  token, error = process.communicate()
  if(process.poll() != 0):
    raise "Couldn't access server token"
  token = token.rstrip()
  rcli = "rudder-cli --skip-verify --url=" + rudder_url + " --token=" + token

  scenario.lib.scenario = scenario.lib.Scenario(platform, rspec, rcli, server_name, frmt, run_only)
  scenario.lib.env(client_path, rudder_url, token)
  import scenario.base
