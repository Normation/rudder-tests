rudder-tests
============

Automatic tests repository

To run Rudder Test Framework, first prepare the needed tools:
- checkout https://github.com/Normation/rudder-tests
- install rudder-cli (checkout https://github.com/Normation/rudder-api-client and type ./build.sh in its lib.python)
- make a link to rudder api client : ln -s ~/repos/rudder-api-client
- install ruby 2
- install jq
- install serverspec http://serverspec.org/ (gem install serverspec)
- install docopt, requests, pexpect and urllib3 python modules (pip install docopt requests pexpect urllib3)
- run `make` in the `script` directory

Run the desired test platform:
- ./rtf platform setup debian 

Run a test scenario:
- ./rtf scenario run debian base


rtf documentation
-----------------
        ./rtf --help
        
        Rudder test framework
        
        Usage:
            rtf platform list
            rtf platform status <platform>
            rtf platform setup <platform> [<version>]
            rtf platform destroy <platform>
            rtf platform update-rudder <platform> <version>
            rtf platform update-os <platform> <version>
            rtf host list <platform>
            rtf host update-rudder <host> <version>
            rtf host update-os <host> <version>
            rtf scenario list
            rtf scenario run <platform> <scenario> [--no-finally] [--filter=<test1>,<test2>,...] [--format=<format>]
        
          Options:
            --no-finally       Do not run tests tagged FINALLY in the scenario, to avoid coming back to initial state
            --filter=...       Only run provided test list from scenario
            --format=<format>  Output format to use (progress, documentation, html or json) [Default: documentation]


Writing tests
-------------
Tests are in spec/tests/

Just copy an existing test, and it can be used.

- Tests are serverspec files. They use a common code that can be found in spec/spec_helper.rb.
- Test parameters are provided vira environment_variables. Environment variables named RUDDER_* are already parsed into a global array named $params
- Tests consist of examples that are executed in order and their result is checked using rspec syntax
- Examples should be ressource types from serverspec: http://serverspec.org/resource_types.html
- Access to rudder api is provided by a prepared command line in the variable $rcli (equivalent to calling ./rudder-cli in rudder-api-client) 
- Tests should use parameters to not be specific to a scenario


Writing a scenario
------------------
Scenarii are in scenario/

A scenario is a list of commands to run tests in order with parameters.

A typical scenario:
        from scenario.lib import *
        start()
        run('hostname', 'test', Err.CONTINUE, PARAM=value)
        ...
        finish()

- Scenarii are python modules
- A global variable called scenario contains all necessary informations to run the scenario
- Some functions are available to help running tests, they are in scenario/lib.py
- Each tests has an error mode that tells what to do in case of error 
  - CONTINUE: continue testing even if this fail, should ne the default
  - BREAK: stop the scenario if this fail, for tests that change a state
  - FINALLY: always run this test, for leaning after a scenario, broken or not
- You can include a scenario from another one, just call import scenario.subscenario within your scenario
- Some methods are provided to iterate a test over current platform nodes 


Adding a platform or an OS
--------------------------
OS are based on atlas vagrant boxes https://atlas.hashicorp.com/boxes/search?vagrantcloud=1
To add a new box, just add a varianble in the existing list in vagrant.rb

Platforms are in platforms/

- Platforms are a list of vm with a configuration that are related in a scenario.
- Platforms are described in json format
- A scenario may have some dependency on a platform content such as host types and names
- The "default" entry in inherited by all other entries
- Each entry is a node name
- A node name should be "server" or "agentX", this is an assumption in some scenario and in the cleanbox initialization script
- "rudder-setup" describe the type of setup, currently only "agent" and "server" are supported
- "system" is one of the variable of known boxes from vagrant.rb
- "osname" is a substring of the OS name that is discovered by fusion (this is used by the fusion test)


Adding a new host format
------------------------
Everything on host is done through the Host class in rtf.

The only Host class is currently Vagrant. To implement the support of a new format you should create a new class implementing the same methods as Vagrant and deplare it in the host_types variable.

