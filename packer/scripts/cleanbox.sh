#!/bin/sh

# Various cleanups to apply on the Vagrant boxes we use.
# no set -e since some things are expected to fail

SCRIPTS_PREFIX="/vagrant"
if [ "$1" != "" ]; then
  SCRIPTS_PREFIX=$1
fi

postclean() {
  ### THINGS TO DO ON AN ALREADY CLEAN BOX
  if type curl >/dev/null 2>/dev/null
  then
    curl -L -s -o /usr/local/bin/rudder-setup https://repository.rudder.io/tools/rudder-setup
    curl -L -s -o /usr/local/bin/ncf-setup https://repository.rudder.io/tools/ncf-setup
  else
    wget -q -O /usr/local/bin/rudder-setup https://repository.rudder.io/tools/rudder-setup
    wget -q -O /usr/local/bin/ncf-setup https://repository.rudder.io/tools/ncf-setup
  fi

  chmod +x /usr/local/bin/rudder-setup /usr/local/bin/ncf-setup
  cp $SCRIPTS_PREFIX/scripts/ncf /usr/local/bin/
  cp $SCRIPTS_PREFIX/scripts/lib.sh /usr/local/bin/
  cp $SCRIPTS_PREFIX/scripts/version-test.sh /usr/local/bin/
  chmod +x /usr/local/bin/ncf

  id > /tmp/xxx
}

# Temporary (event clean box don't have that yet
# Move it to Dirty below when ready
if [ -f /etc/yum.conf ] && [ $(getconf LONG_BIT) == 64 ]
then
  echo "exclude=*.i386 *.i686" >> /etc/yum.conf
fi

. common.sh

# package that should exist everywhere
${PM_INSTALL} zsh vim less curl binutils rsync tree ntp htop dos2unix zip python
${PM_INSTALL} git || ${PM_INSTALL} git-core
# install that may fail
${PM_INSTALL} htop ldapscripts uuid-runtime tree

# Temporary bis
if [ $(uname -m) = "x86_64" ]
then
  curl -L -s -o /usr/bin/jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
  chmod +x /usr/bin/jq
elif [ $(uname -m) = "i386" ]
then
  curl -L -s -o /usr/bin/jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux32"
  chmod +x /usr/bin/jq
fi

# box is clean
if [ -f /root/clean ]
then
  postclean
  exit 0
fi


### THINGS TO DO ON A DIRTY BOX

# remove "stdin: not a tty" error on some box
[ -e /root/.profile ] && sed -e 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile > /root/.profile2 2>/dev/null && mv /root/.profile2 /root/.profile

# Enable SELinux (all)
if [ -f /etc/sysconfig/selinux ]
then
  setenforce 1 2>/dev/null
  sed -i -e 's/^SELINUX=.*/SELINUX=enabled/' /etc/sysconfig/selinux
fi

# Disable firewall (RHEL)
if [ -f /etc/redhat-release ]
then
  chkconfig iptables off 2>/dev/null
  chkconfig firewalld off 2>/dev/null
  service iptables stop 2>/dev/null
  service firewalld stop 2>/dev/null
fi

# Setup Debian / Ubuntu packaging (debian/ubuntu)
if type apt-get 2>/dev/null
then
  export DEBIAN_FRONTEND=noninteractive

  # pre answer interactive questions from oracle
  cat << EOF | debconf-set-selections
sun-java6-bin   shared/accepted-sun-dlj-v1-1    boolean true
sun-java6-jre   shared/accepted-sun-dlj-v1-1    boolean true
oracle-java8-installer  shared/present-oracle-license-v1-1  note
oracle-java8-installer  shared/accepted-oracle-license-v1-1 boolean true
oracle-java8-installer  shared/error-oracle-license-v1-1  error
oracle-java8-installer  oracle-java8-installer/not_exist  error
oracle-java8-installer  oracle-java8-installer/local  string
EOF

  # Replace repos by archive for Debian Squeeze
  grep -e "^6\." /etc/debian_version > /dev/null
  squeeze=$?
  if [ $squeeze -eq 0 ] ;
  then
    echo "deb http://archive.debian.org/debian/ squeeze main" > /etc/apt/sources.list
  fi

  apt-get update

  # make sure lsb_release command is available
  apt-get install --force-yes -y lsb-release

  # Old Ubuntu releases need to use the old-releases mirror instead of the default one
  if hash lsb_release 2>/dev/null
  then
    if [ "$(lsb_release -cs)" = "quantal" ]
    then
      echo "deb http://old-releases.ubuntu.com/ubuntu/ quantal main restricted universe" > /etc/apt/sources.list
      echo "deb http://old-releases.ubuntu.com/ubuntu/ quantal-updates main restricted universe" > /etc/apt/sources.list
      apt-get update
    fi

    # Ubuntu raring & wily need to use the old-releases mirror instead of the default one
    # If any rackspace repo are there, replace them
    if [ "$(lsb_release -cs)" = "raring" ] || [ "$(lsb_release -cs)" = "wily" ]
    then
      sed -i -e 's/archive.ubuntu.com\|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list
      sed -i -e 's/us.old-releases/old-releases/' /etc/apt/sources.list
      sed -i -e 's/mirror.rackspace/old-releases.ubuntu/g' /etc/apt/sources.list
    fi
  fi



  if hash service 2>/dev/null
  then
    :
  else
    apt-get install --force-yes -y sysvconfig
  fi

  apt-get install --force-yes -y apt-transport-https

  # specific to debian7 / rudder server 2.11.6-4
  apt-get install --force-yes -y libltdl7
fi

if [ -f /etc/debian_version ]
then
  DEBIAN_VERSION=`cat /etc/debian_version | cut -d'.' -f1`
fi

# Setup SLES packaging (suse)
if [ -f /etc/SuSE-release ]
then

  # Get the running SLES version
  SLES_VERSION=`grep "VERSION" /etc/SuSE-release|sed "s%VERSION\ *=\ *\(.*\)%\1%"`
  SLES_SERVICEPACK=`grep "PATCHLEVEL" /etc/SuSE-release|sed "s%PATCHLEVEL\ *=\ *\(.*\)%\1%"`

  ln -s /usr/sbin/update-alternatives /usr/sbin/alternatives
  if [ "$(uname -m)" = "x86_64" ]
  then

    if [ ${SLES_VERSION} -eq 12 ] && [ ${SLES_SERVICEPACK} -ge 1 ]
    then
      # do not preinstall java on sles12
      true
    else
      echo "Installing JDK8"
      wget -q -O /tmp/jdk.rpm https://repository.rudder.io/build-dependencies/java/jdk-8u101-linux-x86_64.rpm
      rpm -iv /tmp/jdk.rpm | grep '^.$' || true
    fi

    rm -f /etc/zypp/repos.d/*.repo

    # Add the repositories corresponding to the running SLES version
    if [ ${SLES_VERSION} -eq 11 ] && [ ${SLES_SERVICEPACK} -eq 1 ]
    then
      zypper ar -f "http://192.168.180.1/SLE-11-SP1-Server-DVD-x86_64-GM-DVD1/" "SLES_11_SP1_DVD1" > /dev/null
      zypper ar -f "http://192.168.180.1/SLE-11-SP1-Server-64-SDK-DVD1/"        "SLES_11_SP1_DVD2" > /dev/null
    fi

    if [ ${SLES_VERSION} -eq 11 ] && [ ${SLES_SERVICEPACK} -eq 3 ]
    then
      zypper ar -f "http://192.168.180.1/SLE-11-SP3-Server-DVD-x86_64-GM-DVD1/" "SLES_11_SP3_DVD1" > /dev/null
      zypper ar -f "http://192.168.180.1/SLE-11-SP3-Server-DVD-x86_64-GM-DVD2/" "SLES_11_SP3_DVD2" > /dev/null
    fi

    if [ ${SLES_VERSION} -eq 12 ] && [ ${SLES_SERVICEPACK} -eq 1 ]
    then
      zypper ar -f "http://192.168.180.1/SLE-12-SP1-Server-DVD-x86_64-GM-DVD1/" "SLES_12_SP1_DVD1" > /dev/null
      zypper ar -f "http://192.168.180.1/SLE-12-SP1-Server-DVD-x86_64-GM-DVD2/" "SLES_12_SP1_DVD2" > /dev/null
      # preinstall mod_wsgi
      zypper --non-interactive install apache2 | grep '^.$'
      rpm -iv http://download.opensuse.org/repositories/Apache:/Modules/SLE_12_SP1/x86_64/apache2-mod_wsgi-4.5.2-58.1.x86_64.rpm
    fi

    if [ ${SLES_VERSION} -eq 12 ] && [ ${SLES_SERVICEPACK} -eq 2 ]
    then
      zypper ar -f "http://192.168.180.1/SLE-12-SP1-Server-DVD-x86_64-GM-DVD1/" "SLES_12_SP1_DVD1" > /dev/null
    fi

  else
    if [ ${SLES_VERSION} -eq 12 ] && [ ${SLES_SERVICEPACK} -ge 1 ]
    then
      true
    else
      echo "Installing JDK8"
      wget -q -O /tmp/jdk.rpm https://repository.rudder.io/build-dependencies/java/jdk-8u101-linux-i586.rpm
      rpm -iv /tmp/jdk.rpm | grep '^.$' || true
    fi
  fi

fi


# add common useful files
for user in root vagrant
do
  home=`getent passwd ${user} | cut -d: -f6`
  rsync -rl $SCRIPTS_PREFIX/scripts/files/ "${home}"/
done

postclean
exit 0
