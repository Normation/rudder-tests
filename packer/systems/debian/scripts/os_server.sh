#!/bin/bash

set -xe

export DEBIAN_FRONTEND=noninteractive

# relay
apt-get install -y jq libjq1 libonig5 libyaml-0-2
# server
apt-get install -y postgresql rsyslog-pgsql iproute2 rsyslog python3 apache2 apache2-utils git-core rsync lsb-release openssl ldap-utils postgresql-client openjdk-11-jre-headless curl acl
