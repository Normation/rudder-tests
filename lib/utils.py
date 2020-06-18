from subprocess import Popen, PIPE

# Run a command in a shell like a script would do
# And inform the user of its execution
def shell(command, fail_exit=True, keep_output=True, live_output=False, quiet=False):
  if not quiet:
     print("+" + command)
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

