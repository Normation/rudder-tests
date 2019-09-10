#!/bin/sh

if [ -d /opt/rudder/jetty7 ]; then
  cp -a /vagrant/dev/fake-rudder.war /opt/rudder/jetty7/webapps/rudder.war
else
 cp -a /vagrant/dev/fake-rudder.war /opt/rudder/share/webapps/rudder.war
fi

service rudder-jetty restart
