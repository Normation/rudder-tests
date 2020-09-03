# rudder-tests
This project is meant to make Rudder scenarios testing easier.
It is aimed to test the final system on real conditions, unit testing
should not be done using this tool.

A scenario is an ordered execution of steps and individual tests applied on an infrastructure.
Scenarios are recursive and so, a scenario can call another scenario.

## Dependencies

```
pip install jsonschema
pip install testinfra
pip install paramiko
pip install pytest-json-report

```

## Invocation

There are no proper test runner at the moment.
To trigger a test run, modify the `run.py` file. The call to the local function *run_scenario* will execute the given scenario.

In order to run a scenario, you will need:

* A *datastate* file,
* An *input*,
* And a scenario name

### Datastate

A datastate file is a JSON based file describing the infrastructure on which the scenario will be executed.
The test runner will be use the informations from the datastate to communicate and identify the machines.
If you did setup your test infra using the `rtf` CLI, you can dump your platform datastate using:

Each scenario should expected a specific infrastructure to work properly, they are described using a jsonschema
format in the scenario code. Before running a scenario, the runner will check the sanity of the datastate you are
trying to use for a given scenario.


```
./rtf platform dump <my platform name> > data.json
```

Ex:
```
{
  "windows_agent1": {
    "ip": "127.0.0.1",
    "provider": "virtualbox",
    "role": "agent",
    "rudder-setup": "agent",
    "rudder-version": "ci/6.1-1.20-nightly",
    "server": "server",
    "ssh_cred": "",
    "ssh_port": 2222,
    "ssh_user": "Administrator",
    "system": "windows2019"
  },
  "windows_server": {
    "ip": "127.0.0.1",
    "provider": "virtualbox",
    "role": "server",
    "rudder-setup": "server",
    "rudder-version": "6.1.3",
    "server": "server",
    "ssh_cred": "",
    "ssh_port": 2200,
    "ssh_user": "vagrant",
    "system": "ubuntu18",
    "webapp_url": "https://localhost:8481//rudder"
  }
}
```

### Input

The input file is a json containing whatever data you want to pass to the scenario you are trying to run.
Each scenario has its own expected input if any, currently no verification is done before running a scenario
on the input data. Refer to the scenario code to see what input it requires.


## Reports

#### JSON based reports

All testinfra based scenarios execution result in a JSON base report.
Its structure is described in the lib/reports.py file.

#### XML based reports

All legacy scenarios run result in a local `result.xml` file in JUnit format.
It can easily be read using tools such as xunit-viewer.

```
# To produce an html report
xunit-viewer -r result.xml -o result.html

# To render it in the console
xunit-viewer -c -r ./result.xml
```
