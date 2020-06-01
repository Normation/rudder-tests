Handlibng tests
===============

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

Writing a technique test
------------------------

Technique tests use a special scenario to test a technique. The are localed in the technique folder,
in a `tests` directory, containing:

- `my_test.metadata`: The main file, in JSON, containing information about the test, for example the global compliance and the paths of other test files.
- `my_test.json`: The directive parameters for the test.
- `my_test.rb`: The serverspec file containing the actual test. It should check if the directive was correctly applied.
- `my_test.cf`(optionnal): A CFEngine policy to enforce before starting the test, to prepare the environement.

This content can be generated from an existing directive, using:

`rtf test from-directive <platform> <directiveid> <test_name> <destination_path>`


