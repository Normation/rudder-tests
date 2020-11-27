import re
import testinfra
import pytest

@pytest.fixture
def etag(test_data):
    return test_data["etag"]
@pytest.fixture
def update(test_data):
    return test_data["update"]
@pytest.fixture
def file_to_lock(test_data):
    if "file_to_lock" in test_data:
      return test_data["file_to_lock"]

### Utility functions below

def unzip(json_metadata, host, zip_file, dst):
  cmd = "[System.IO.Compression.ZipFile]::ExtractToDirectory(" + zip_file + ", " + dst + ")"
  ret = run_cmd(json_metadata, host, cmd)
  return ret.sterr == ""

def directory_exists(json_metadata, host, directory):
  cmd = "Test-Path -PathType Container -Path \"" + directory + "\""
  ret = run_cmd(json_metadata, host, cmd)
  return ret.stdout.strip() == "True"

def getContent(json_metadata, host, target):
  cmd = "Get-Content -Path \"" + target + "\""
  ret = run_cmd(json_metadata, host, cmd)
  return ret.stdout.strip()

def compareFolders(json_metadata, host, folder1, folder2):
  cmd = "Compare-Object -ReferenceObject $(Get-ChildItem -Path '" + folder1 + "' -Recurse) -DifferenceObject $(Get-ChildItem -Path '" + folder2 + "' -Recurse)"
  ret = run_cmd(json_metadata, host, cmd)
  return (ret.stderr == "" and ret.stdout == "")


"""
  Cmd runs should never throw exceptions
"""
def run_cmd(json_metadata, host, cmd):
  ret = host.run(cmd)
  json_metadata["commands"].append({"cmd": cmd, "stdout": ret.stdout.strip(), "stderr": ret.stderr.strip(), "succeeded": ret.succeeded})
  assert ret.stderr == ""
  return ret



#### Test functions below
"""
  Policy must be the same than the ones in zip file + etag.
  Backup must be updated to be the same than the zip file.
  Etag must be updated.
"""
def update_test(json_metadata, host, token, webapp_url, etag, update, rudder_base):
  # update must succeed
  ret = run_cmd(json_metadata, host, "rudder agent update")
  assert "Policies successfully updated" == ret.stdout.strip()

  # policy folder and backups should be the same, only the etag should differ.
  compare_cmd = "Compare-Object -ReferenceObject $(Get-ChildItem -Path '" + rudder_base + "/policy' -Recurse) -DifferenceObject $(Get-ChildItem -Path '" + rudder_base + "/policy.bkp' -Recurse)"
  compare = run_cmd(json_metadata, host, compare_cmd)
  assert compare.stdout.strip() == "InputObject SideIndicator\r\n----------- -------------\r\nrudder.etag <="
  assert getContent(json_metadata, host, rudder_base + "/policy/rudder.etag") == etag

  # Backups and zip content must be the same
  #TODO




"""
  Lock a file.
  Policy must be:
    * the same as the backup folder if it exists
    * initial policies else
  Backup must be updated to be the same than the zip file.
  Etag must remain the same to trigger update next run.
  Release the lock.
"""
def fallback_test(json_metadata, host, token, webapp_url, etag, update, rudder_base, file_to_lock, fallback):
  before_update_etag = getContent(json_metadata, host, rudder_base + "/policy/rudder.etag")
  # update must fail
  ret = run_cmd(json_metadata, host, "$file=[System.IO.File]::Open(\"" + file_to_lock + "\", \"Open\", \"Write\", \"None\");rudder agent update; $file.close()")

  fallback_path = ""
  if fallback == "backups":
    fallback_path = rudder_base + "/policy.bkp"
    assert "Couldn't extract policies, fallback to the backup ones" == ret.stdout.strip()
  elif fallback == "initial-policies":
    fallback_path = rudder_base + "/share/initial-policy"
    assert "No backup policies found, using initial policies as backup\r\nCouldn't extract policies, fallback to the backup ones" == ret.stdout.strip()

  compare_cmd = "Compare-Object -ReferenceObject $(Get-ChildItem -Path '" + rudder_base + "/policy' -Recurse) -DifferenceObject $(Get-ChildItem -Path '" + fallback_path + "' -Recurse)"

  # Etag must remain the same
  assert before_update_etag != etag
  assert getContent(json_metadata, host, rudder_base + "/policy/rudder.etag") == before_update_etag

  # Backups and zip content must be the same
  #TODO



"""
  Policy must remain the same
  Backup must remain the same
  Etag   must remain the same
"""
def keep_test(json_metadata, host, token, webapp_url, etag, update, rudder_base, message):
  # Since getting hash of a folder content is quite difficult in powershell, simply keep all file hashes from it
  cmd1 = "gci -recurse -path \"" +rudder_base + "/policy\" -exclude *rudder.etag | Get-FileHash -Algorithm MD5 | select-object hash | foreach-object { $_.Hash }"
  cmd2 = "gci -recurse -path \"" +rudder_base + "/policy.bkp\" -exclude *rudder.etag | Get-FileHash -Algorithm MD5 | select-object hash | foreach-object { $_.Hash }"
  before_update_policy_hash = run_cmd(json_metadata, host, cmd1).stdout.strip()

  # update must do nothing
  ret = run_cmd(json_metadata, host, "rudder agent update")
  assert message == ret.stdout.strip()

  # Compare initial policies, after update policy folder and backup, they should all be the same
  after_update_policy_hash = run_cmd(json_metadata, host, cmd1).stdout.strip()
  after_update_bkp_hash = run_cmd(json_metadata, host, cmd2).stdout.strip()

  assert after_update_policy_hash == after_update_bkp_hash
  assert after_update_policy_hash == before_update_policy_hash

  # Etag should be up-to-date
  assert getContent(json_metadata, host, rudder_base + "/policy/rudder.etag") == etag



"""
  Main test, cases:
    * to_update                 => Standard case, when the policies need to be updated
    * keep                      => Policies are already up to date
    * fail                      => Early fail of update, for instance the server is unreachable.
                                   the policies must be preserved
    * backup                    => Something went wrong, fallback to backup or initial policies
    * fallback-backup-policies  => Lock a policy file, so it can not be edited. Fallback to backups.
    * fallback-initial-policies => Lock a policy file, so it can not be edited. Fallback to initial
                                   policies.

  Common things:
    * policy and policy.bkp folders should always exists and never be empty
    * update command should never throw exceptions
"""
def test_update(json_metadata, host, token, webapp_url, etag, update, file_to_lock):
  if "commands" not in json_metadata:
    json_metadata["commands"] = []
  rudder_base = "C:/Program Files/Rudder"

  if update == "to_update":
    update_test(json_metadata, host, token, webapp_url, etag, update, rudder_base)
  elif update == "keep":
    keep_test(json_metadata, host, token, webapp_url, etag, update, rudder_base, "Policies already up to date")
  elif update == "fail":
    keep_test(json_metadata, host, token, webapp_url, etag, update, rudder_base, "Couldn't download policy from server")
  elif update == "fallback-backup-policies":
    fallback_test(json_metadata, host, token, webapp_url, etag, update, rudder_base, file_to_lock, "backups")
  elif update == "fallback-initial-policies":
    fallback_test(json_metadata, host, token, webapp_url, etag, update, rudder_base, file_to_lock, "initial_policies")
  else:
    assert "Should never happen" == ""

  # Common assertions
  assert directory_exists(json_metadata, host, rudder_base + "/policy")
  assert directory_exists(json_metadata, host, rudder_base + "/policy.bkp")

