from subprocess import Popen, check_output, PIPE, CalledProcessError
class colors:
    BLACK   = "\u001b[30;1m"
    RED     = "\u001b[31;1m"
    GREEN   = "\u001b[32;1m"
    YELLOW  = "\u001b[33;1m"
    BLUE    = "\u001b[34;1m"
    MAGENTA = "\u001b[35;1m"
    CYAN    = "\u001b[36;1m"
    WHITE   = "\u001b[37;1m"
    RESET   = "\u001b[0m"

"""
  Find and replace occurences of a string in
  a json data

  INPUT:
    * username
    * directive_id
    * directive_name
    * rule_id
    * rule_name
"""
def replace_value(data, old_value, new_value):
    if type(data) is dict:
        for key, value in data.items():
            data[key] = replace_value(value, old_value, new_value)
        return data
    elif type(data) is list:
        for idx, val in enumerate(data):
            data[idx] = replace_value(val, old_value, new_value)
        return data
    else:
        if data == old_value:
            return new_value
        else:
            return data

# This method is used to prevent running new test in cases of error
def enum(*sequential, **named):
  """ Enum compatibility for old python versions """
  enums = dict(zip(sequential, range(len(sequential))), **named)
  return type('Enum', (), enums)

def shell(command, fail_exit=True, keep_output=True, live_output=False):
  print(colors.WHITE + "+" + command + colors.RESET)
  if keep_output:
    if live_output:
      process = Popen(command, shell=True, universal_newlines=True)
    else:
      process = Popen(command, stdout=PIPE, shell=True, universal_newlines=True)
    output, error = process.communicate()
    retcode = process.poll()
  else: # keep tty management and thus colors
    process = Popen(command, shell=True)
    retcode = process.wait()
    output = None
  if fail_exit and retcode != 0:
    print(command)
    print("*** COMMAND ERROR " + str(retcode))
    exit(1)
  return (retcode, output)

"""
  Convert a datastate host to a basic usable ssh-conf file
"""
def datastate_to_ssh(hostname, host, dst):
  if hostname != "localhost":
    with open(dst, "w") as f:
      f.write("""Host {0}
  HostName {1}
  User {2}
  Port {3}
  IdentityFile {4}
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
""".format(hostname, host["ip"], host["ssh_user"], host["ssh_port"], host["ssh_cred"]))

