import pytest
import json


def pytest_addoption(parser):
    parser.addoption("--test_data", action="store", default={})
    parser.addoption("--token", action="store", default="")
    parser.addoption("--webapp_url", action="store", default="")



@pytest.fixture
def test_data(request):
    return json.loads(request.config.getoption("--test_data"))

@pytest.fixture
def token(request):
    return request.config.getoption("--token")

@pytest.fixture
def webapp_url(request):
    return request.config.getoption("--webapp_url")
