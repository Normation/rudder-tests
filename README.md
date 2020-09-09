rudder-tests
============

Automatic tests repository

See doc/INSTALL.md for test setup

Run the desired test platform:
- ./rtf platform setup debian 

Run a test scenario:
- ./rtf scenario run debian base

Get the long help:
- ./rtf --help


Dependencies
---------
They are several python dependencies to use rtf:

```
python-netifaces
```

Use cases
---------

Every parameter after the platform name in "./rtf platform setup" is an additional parameter to the platform, ie it a key=value that is identical to the ones available in the platform.json file.
Examples of such parameters:
- rudder-version=ci/6.0 (this one can be abbreviated to "6.0")
- live=true : do not use buffers for output (this make the output more reactive, but produces more fake lines because of progress bars)
- plugins=all : install all available plugins (you can specify a space separated list of plugins instead)
- plugins_version=nightly : by default release versions of plugins are installed (ci and ci/nightly are also available)
- forget_credential=true : to avoid keeping your download credentials on the vm (useful if you are going to export the platform)
- provider=aws : to instantiate the platform on aws see doc/PROVIDERS.md for more details

Global parameters can be put directly in the Vagrantfile.
Examples of such parameters:
- $NETWORK (default 192.168.40.0/24) : the first network to use for the first platform, next platform will use next available network
- $SKIP_IP : number of IP to avoid using in this network (because they are used for the gateway for example)
- $DOWNLOAD_USER and $DOWNLOAD_PASSWORD : credential to download licences and private plugins

Run a platform on AWS (see doc/PROVIDERS.md for details) :
- you must have the vagrant-aws plugin installed
- the $AWS... global parameters must be filled
- use provider=aws in the platform description
- that's all

See doc/TESTS.md to ad new tests and scenarios
