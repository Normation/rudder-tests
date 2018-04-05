#!/bin/sh

# This script sets up the server environment for the demo platform

# We need unzip for now
if type apt-get 2> /dev/null
then
  PM_INSTALL="apt-get -y install"
elif type yum 2> /dev/null
then
  # Fix Centos5 issue installing, which install both architecture, this has no effects on other distros
  echo "multilib_policy=best" >> /etc/yum.conf
  PM_INSTALL="yum -y install"
elif type zypper 2> /dev/null
then
  PM_INSTALL="zypper --non-interactive install"
fi
${PM_INSTALL} unzip

curl -s -o rudder-demo.zip https://www.normation.com/download/rudder-demo.zip
unzip -o rudder-demo.zip -d /var/rudder/configuration-repository
# tar -zxvf rudder-demo-server.tgz -C /var/rudder/configuration-repository/
cd /var/rudder/configuration-repository/
chown -R root:rudder directives groups parameters ruleCategories rules techniques
chown -R ncf-api-venv:rudder ncf/50_techniques techniques/ncf_techniques
git add . && git commit -am "Importing configuration"
curl -s -k https://localhost/rudder/api/archives/restore/full/latestCommit
