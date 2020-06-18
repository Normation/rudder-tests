import random
import time
import os
import shutil
import copy
import re
import socket
import pexpect
import requests
import fcntl
from .utils import shell

use_proxy = ''
def have_proxy():
  """ Return proxy configuration if any """
  global use_proxy
  nrm_proxy = "http://filer.interne.normation.com:3128"
  proxy_line = "http_proxy="+nrm_proxy+" https_proxy="+nrm_proxy+" HTTP_PROXY="+nrm_proxy+" HTTPS_PROXY="+nrm_proxy+" "
  if use_proxy != '':
    return use_proxy
  socket.gethostbyname(socket.gethostname())
  s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  s.connect(("8.8.8.8", 80))
  if s.getsockname()[0].startswith('192.168.90.'):
    nrm_ip = socket.gethostbyname("republique-1.normation.com.")
    req = requests.get("http://ipinfo.io/ip")
    if req.status_code == 200:
      if req.content.strip() == nrm_ip:
        use_proxy = proxy_line
  return use_proxy

class Host:
  """ Vagrant managed host """
  def __init__(self, platform, name, host_info):
    pf = platform.split('.')[0]
    self.info = host_info
    self.platform = pf
    self.name = name
    self.hostid = pf + '_' + name
    self.provider = host_info["provider"]
    self.commands = {}

  def start(self):
    """ Setup and run this host """
    proxy = have_proxy()
    lockFile = "/tmp/rtf-lock"
    f = open(lockFile, "w+")
    while "making sure that no vagrant up are running":
      try:
        fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
        break
      except IOError:
          idle = random.randint(5, 10)
          print("Lock not available, waiting %s seconds"%idle)
          time.sleep(idle)
    ret = os.system(proxy + "vagrant up " + self.hostid + " --provider="+self.provider)
    fcntl.flock(f, fcntl.LOCK_UN)
    f.close()
    return ret

  def stop(self):
    """ Destroy this host """
    return os.system("vagrant destroy -f " + self.hostid)

  def reprovision(self):
    """ Just run provisioning script this host """
    return os.system("vagrant provision " + self.hostid)

  def halt(self):
    """ Halt this host """
    return os.system("vagrant halt " + self.hostid)

  def snapshot(self, name):
    """ Snapshot this host """
    return os.system("vagrant snapshot save " + self.hostid + " " + name)

  def rollback(self, name):
    """ Go to last snapshot on this host """
    return os.system("vagrant snapshot restore " + self.hostid + " " + name)

  def snapshot_delete(self, name):
    """ Remove last snapshot on this host """
    return os.system("vagrant snapshot pop " + self.hostid + " " + name)

  def export(self, directory):
    """ Export this VM using Virtualbox commads """
    fullname = os.path.basename(os.getcwd()).replace('.', '') + '_' + self.hostid
    # List VMs and do something on the one we are working on
    for line in os.popen("VBoxManage list vms"):
      m = re.match(r'"' + fullname + r'[0-9_]+" \{(.*)\}', line)
      if m:
        uuid = m.group(1)
        running = False
        print("Exporting " + fullname + " / " + uuid + " to directory " + directory)
        # If the VM is running, pause it (and save its state) and rerun it later
        for running_line in os.popen("VBoxManage list runningvms"):
          if re.search(uuid, running_line):
            running = True
        if running:
          os.system("VBoxManage controlvm " + uuid + " savestate")
        os.system("VBoxManage clonevm " + uuid + " --options keepallmacs --options keepdisknames --name " + self.hostid + " --basefolder " + directory)
        disk_uuid = ""
        # work around a virtualbox bug, when you clone a vm, the new disk is registered, whateverthe parameters -> unregister it
        for disk_line in os.popen("VBoxManage list hdds"):
          m = re.match(r'UUID:\s+([0-9a-f\-]+)', disk_line)
          if m:
            disk_uuid = m.group(1)
          if re.match(r'Location:\s+'+directory+'/'+self.hostid, disk_line):
            os.system("VBoxManage closemedium disk " + disk_uuid)
        if running:
          os.system("VBoxManage startvm " + uuid + " --type headless")

  def ssh_config(self, key_directory):
    """ get ssh configuration to connect to this machine """
    (code, output) = shell("vagrant ssh-config " + self.hostid, fail_exit=False)
    if code != 0:
      print("Cannot get ssh-configuration for " + self.hostid)
      print("A patch for vagrant is available here https://github.com/peckpeck/vagrant/commit/93c5b853511548087fba7e8813c34ee45226e1cc")
      print("Halting!")
      exit(14)
    m = re.search(r'\sIdentityFile\s+(\S+)', output)
    if m:
      src = m.group(1)
      output = re.sub(r'(\sIdentityFile)\s+\S+', r'\1 '+os.path.basename(key_directory)+'/'+self.hostid, output)
      shutil.copy(src, key_directory+'/'+self.hostid)
    return output

  def get_version(self):
    """Get rudder version (x.y) if any"""
    if 'rudder-version' not in self.info:
      return None
    m = re.search('(\d+\.\d+)', self.info['rudder-version'])
    if m:
      return float(m.group(1))
    else:
      return 7.0 # not used currently but this is fragile (may be latest or nightly)

  def run(self, command, fail_exit=True, live_output=False, quiet=True):
    """ Run a command as root on this host """
    if quiet:
      q="-q"
    else:
      q=""
    (code, value) = shell("vagrant ssh " + self.hostid + " -c \"sudo /bin/sh -c 'PATH=\\$PATH:/vagrant/scripts LANG=C " + command + "'\" -- " + q, fail_exit=fail_exit, live_output=live_output, quiet=quiet)
    if not live_output:
      token = re.sub('==>.*\n', '', value)
      return token.rstrip()

  def run_with_ret_code(self, command, fail_exit=True, live_output=False, quiet=True):
    """ Run a command as root on this host """
    if quiet:
      q="-q"
    else:
      q=""
    (code, value) = shell("vagrant ssh " + self.hostid + " -c \"sudo /bin/sh -c 'PATH=\\$PATH:/vagrant/scripts LANG=C " + command + "'\" -- " + q, fail_exit=fail_exit, live_output=live_output, quiet=quiet)
    if not live_output:
      token = re.sub('==>.*\n', '', value)
      return (code, token.rstrip())
    return (code, "")

  def cached_run(self, command, fail_exit=True):
    if command in self.commands:
      return self.commands[command]
    value = self.run(command, fail_exit)
    self.commands[command] = value
    return value

  def push(self, source, destination):
    shell("vagrant scp \"" + source + "\" \"" + self.hostid + ":" + destination + "\"")

  def pull(self, source, destination):
    shell("vagrant scp \"" + self.hostid + ":" + source + "\" \"" + destination + "\"")

  def push_techniques(self, directory):
    """ Replace all techniques with the provided ones """
    # First, erase technique directories matching the tested one
    name = os.path.basename(os.path.abspath(directory))
    self.run("cd /var/rudder/configuration-repository/techniques/ && find -mindepth 1 -type d -name " + name + " | xargs rm -rf ", fail_exit=False, live_output=True)
    # Then push new techniques
    self.push(directory, "/tmp/")
    self.run("mv /tmp/" + name + " /var/rudder/configuration-repository/techniques/", live_output=True)
    self.run("cd /var/rudder/configuration-repository/techniques/ && git add --all . && git commit --allow-empty -m 'Replacing all techniques with the test ones' && rudder server reload-techniques", live_output=True)

  def share(self, password):
    """ Shares this box via vagrant cloud """
    # make sure the VM is running
    os.system("vagrant up " + self.hostid)
    # run vagrant share, provide a password, print its output and extract the command to run
    process = pexpect.spawn("/usr/bin/vagrant share --disable-http --ssh "+ self.hostid)
    process.expect("Please enter a password to encrypt the key: ")
    print(process.before, end='')
    process.sendline(password)
    process.expect("Repeat the password to confirm: ")
    print(process.before, end='')
    process.sendline(password)
    process.expect(r'==> \w+: simply has to run `(vagrant connect --ssh .*?)`')
    command = process.match.group(1)
    print(process.before, end='')
    process.expect(r'in some secure way..*')
    print(process.before, end='')
    print(process.after, end='')
    return (self.hostid, command, process)

  def get_url(self):
    """ Get matching server URL """
    for line in open("Vagrantfile"):
      m = re.match(r'### AUTOGENERATED FOR PLATFORM ' + self.platform + r' (.*?) (https://.*/)', line)
      if m:
        return m.group(2)+"/rudder"
      m = re.match(r'### AUTOGENERATED FOR PLATFORM ' + self.platform + r' (.*?) (aws:)', line)
      if m:
        command = "vagrant ssh-config " + self.hostid
        (code, output) = shell(command)
        adress = re.match(r'\s*HostName (.*)', output)
        return "https://" + adress.group(1) + "/rudder"
    return None

  def wait_for_command(self, command, timeout=60):
    print("Waiting " + str(timeout) + "s for command to return ok on " + self.hostid)
    print(command)
    for i in range(1, timeout):
      (code, data) = self.run_with_ret_code(command, fail_exit=False, quiet=True, live_output=True)
      if code == 0:
        print("Done")
        return True
    print("Timeout")
    return False

  def wait_for_generation(self, uuid, date0, timeout=60):
    """ If we are on a server, wait for uuid promises to be generated """
    if 'rudder-setup' not in self.info or self.info['rudder-setup'] != 'server':
      print("ERROR: called wait_for_generation on a non server")
      exit(1)
    file_path = "/var/rudder/share/" + uuid + "/rules/cfengine-community/rudder_promises_generated"
    print("Waiting for " + uuid + " generation")
    return self.wait_for_command("[ -f " + file_path + ' ] && [ \\"\\$(cat ' + file_path + ')\\" -gt ' + date0 + " ]")

