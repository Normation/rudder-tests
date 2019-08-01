#!/bin/sh

sed -i "s/^IP=.*$/IP=*/" /opt/rudder/etc/rudder-slapd.conf 
sed -i "s/^#IP=.*$/IP=*/" /etc/default/rudder-slapd

PG_HBA_FILE=$(su - postgres -c "psql -t -P format=unaligned -c 'show hba_file';")
if [ $? -ne 0 ]; then
  echo "Postgresql failed to start! Halting"
  exit 1
fi

PG_CONF_FILE=$(su - postgres -c "psql -t -P format=unaligned -c 'show config_file';")
if [ $? -ne 0 ]; then
  echo "Postgresql failed to start! Halting"
  exit 1
fi

echo "listen_addresses = '*'" >> ${PG_CONF_FILE}
echo "host    all         all         192.168.42.0/24       trust" >> ${PG_HBA_FILE}
echo "host    all         all         10.0.0.0/16       trust" >> ${PG_HBA_FILE}
/etc/init.d/postgresql restart


if [ -e /opt/rudder/etc/rudder-passwords.conf ] ; then
  sed -i "s/\(RUDDER_WEBDAV_PASSWORD:\).*/\1rudder/" /opt/rudder/etc/rudder-passwords.conf
  sed -i "s/\(RUDDER_PSQL_PASSWORD:\).*/\1Normation/" /opt/rudder/etc/rudder-passwords.conf
  sed -i "s/\(RUDDER_OPENLDAP_BIND_PASSWORD:\).*/\1secret/" /opt/rudder/etc/rudder-passwords.conf
fi

rudder agent run
if [ -d /opt/rudder/jetty7 ]; then
  cp -a /vagrant/dev/fake-rudder.war /opt/rudder/jetty7/webapps/rudder.war
else
 cp -a /vagrant/dev/fake-rudder.war /opt/rudder/share/webapps/rudder.war
fi


service rudder-jetty restart
