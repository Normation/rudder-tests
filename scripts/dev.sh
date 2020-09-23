#!/bin/sh

if [ -d /opt/rudder/jetty7 ]; then
  cp -a /vagrant/dev/fake-rudder.war /opt/rudder/jetty7/webapps/rudder.war
else
  cp -a /vagrant/dev/fake-rudder.war /opt/rudder/share/webapps/rudder.war
fi

sed -i 's/1024/128/g' /etc/default/rudder-jetty

service rudder-jetty restart
