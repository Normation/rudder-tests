rudder-tests setup
==================

Automatic tests repository

To run Rudder Test Framework, first prepare the needed tools:
- checkout https://github.com/Normation/rudder-tests
- install rudder-cli (checkout https://github.com/Normation/rudder-api-client and type ./build.sh in its lib.python)
- make a link to rudder api client : ln -s ~/repos/rudder-api-client
- install ruby 2
- install jq
- install serverspec http://serverspec.org/ (gem install serverspec)
- install python dependencies (pip install docopt requests pexpect urllib3 netifaces)

Additionally you can do this to get better performances:
- run vagrant plugin install vagrant-cachier (to have a cache for packages)
- install the vagrant-aws plugin (you may have to build it by yourself since the only release is a very old one)
- install the vagrant-disksize plugin (vagrant plugin install vagrant-disksize) for specific machine size change

