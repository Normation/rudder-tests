import testinfra

"""
Main test
"""
def test_ncf(host, token, webapp_url):
  cmd = host.run("powershell.exe /c rudder agent tests")
  assert cmd.succeeded
  print(cmd.stdout)

