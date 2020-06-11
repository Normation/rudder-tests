#!/bin/bash

set -xe

export DEBIAN_FRONTEND=noninteractive

# relay
apt-get install -y jq libjq1 libyaml-0-2
# server
apt-get install -y postgresql rsyslog-pgsql iproute2 rsyslog python3 apache2 apache2-utils git-core rsync lsb-release openssl ldap-utils postgresql-client curl acl

if [ "$(lsb_release -sc)" = "buster" ]
then
  apt-get install -y openjdk-11-jre-headless
elif [ "$(lsb_release -sc)" = "stretch" ]
then
  apt-get install -y openjdk-8-jre-headless
else
  echo "Unsupported distro"
  exit 1
fi
