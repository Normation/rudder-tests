import pytest

def pytest_json_modifyreport(json_report):
    del json_report['collectors']
    del json_report['exitcode']
    del json_report['root']
    del json_report['environment']
#    del json_report['tests']['nodeid']
    for t in json_report['tests']:
      for k in ['nodeid', 'lineno', 'keywords']:
        del t[k]
