#!/bin/sh

# Various cleanups to apply on the Vagrant boxes we use.
# no set -e since some things are expected to fail

SCRIPTS_PREFIX="/vagrant"
if [ "$1" != "" ]; then
  SCRIPTS_PREFIX=$1
fi

# add common usefull packages
if type apt-get 2> /dev/null
then
  export DEBIAN_FRONTEND=noninteractive
  PM_INSTALL="apt-get -y install"
elif type yum 2> /dev/null
then
  PM_INSTALL="yum -y install"
elif type zypper 2> /dev/null
then
  PM_INSTALL="zypper --non-interactive install"
elif [ -x /opt/csw/bin/pkgutil ] 2> /dev/null
then
  PM_INSTALL="/opt/csw/bin/pkgutil --install --parse --yes"
else
  PM_INSTALL="echo TODO install "
fi

postclean() {
  if openssl version | grep -q "OpenSSL 0"
  then
    http="http"
  else
    http="https"
  fi
  mkdir -p /usr/local/bin
  if type curl >/dev/null 2>/dev/null
  then
    curl -L -s -o /usr/local/bin/rudder-setup ${http}://repository.rudder.io/tools/rudder-setup
    curl -L -s -o /usr/local/bin/ncf-setup ${http}://repository.rudder.io/tools/ncf-setup
  else
    wget -q -O /usr/local/bin/rudder-setup ${http}://repository.rudder.io/tools/rudder-setup
    wget -q -O /usr/local/bin/ncf-setup ${http}://repository.rudder.io/tools/ncf-setup
  fi

  chmod +x /usr/local/bin/rudder-setup /usr/local/bin/ncf-setup
  cp $SCRIPTS_PREFIX/scripts/ncf /usr/local/bin/
  cp $SCRIPTS_PREFIX/scripts/lib.sh /usr/local/bin/
  cp $SCRIPTS_PREFIX/scripts/version-test.sh /usr/local/bin/
  chmod +x /usr/local/bin/ncf

}

# Temporary (even clean box don't have that yet)
# Move it to Dirty below when ready
if [ -f /etc/yum.conf ] && [ $(getconf LONG_BIT) == 64 ]
then
  echo "exclude=*.i386 *.i686" >> /etc/yum.conf
fi

# Temporary (even clean box don't have that yet)
${PM_INSTALL} tmux

# box is clean
if [ -f /root/clean ]
then
  postclean
  exit 0
fi


### THINGS TO DO ON A DIRTY BOX

# force DNS server to an always valid one (all)
cat << EOF > /etc/resolv.conf
# /etc/resolv.conf, built by rtf (Rudder Test Framwork)
options rotate
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

chattr +i /etc/resolv.conf /etc/resolvconf/run/resolv.conf 2>/dev/null

# remove "stdin: not a tty" error on some box
[ -e /root/.profile ] && sed -e 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile > /root/.profile2 2>/dev/null && mv /root/.profile2 /root/.profile

# Enable SELinux (all)
if [ -f /etc/sysconfig/selinux ]
then
  setenforce 1 2>/dev/null
  sed -i -e 's/^SELINUX=.*/SELINUX=enabled/' /etc/sysconfig/selinux
fi

# French keyboard on console
if [ -f /etc/sysconfig/keyboard ]
then
  cat > /etc/sysconfig/keyboard <<EOF
KEYTABLE="fr"
MODEL="pc105+inet"
LAYOUT="fr"
KEYBOARDTYPE="pc"
EOF
elif [ -f /etc/default/keyboard ]
then
  cat >/etc/default/keyboard <<EOF
XKBMODEL="pc105"
XKBLAYOUT="fr"
XKBVARIANT="latin9"
XKBOPTIONS=""

BACKSPACE="guess"
EOF
fi
loadkeys fr 2>/dev/null

# force root password to root
sed -e 's|^root.*|root:$6$5.6rg6Xl$be5jxAm7/HyoL.3xmgwZRv7XkyqChB1vc.v7VgMeX7Di8C3TtKSgt5DmTFE0PsJxTI8d4eAtE5IRFToFsn4vF/:16638:0:99999:7:::|' /etc/shadow > /etc/shadow2 && mv /etc/shadow2 /etc/shadow

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

  release_opt=$(apt-get --version | head -n1 | perl -ne '/apt ([0-9]+\.[0-9]+)\..*/; if($1 > 1.5) { print "--allow-releaseinfo-change" }')
  apt-get update ${release_opt}

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
    fi

    if [ ${SLES_VERSION} -eq 12 ] && [ ${SLES_SERVICEPACK} -eq 2 ]
    then
      zypper ar -f "http://192.168.180.1/SLE-12-SP1-Server-DVD-x86_64-GM-DVD1/" "SLES_12_SP1_DVD1" > /dev/null
    fi

    if [ ${SLES_VERSION} -eq 12 ] && [ ${SLES_SERVICEPACK} -eq 4 ]
    then
      zypper ar -f "http://192.168.180.1/SLE-12-SP4-Server-DVD-x86_64-GM-DVD1/" "SLES_12_SP4_DVD1" > /dev/null
      zypper ar -f "http://192.168.180.1/SLE-12-SP4-Server-DVD-x86_64-GM-DVD2/" "SLES_12_SP4_DVD2" > /dev/null
    fi

  fi

else
  # check it is a SLES using os-release
  if [ -f /etc/os-release ]
  then
    if  grep -q '^NAME="SLES"' /etc/os-release
    then
      SLES_FULL_VERSION=`grep "VERSION=" /etc/os-release|sed 's%VERSION\ *=\ *"\(.*\)"%\1%'`
      SLES_VERSION=$(echo $SLES_FULL_VERSION | cut -d- -f1)
      SLES_SERVICEPACK=$(echo $SLES_FULL_VERSION | cut -d- -f2)

      # special case : no service pack
      if [ ${SLES_VERSION} -eq 15 ] && [ "${SLES_SERVICEPACK}" = "15" ]
      then
        zypper ar -f "http://192.168.180.1/SLE-15-Installer-DVD-x86_64-GM-DVD1/" "SLES_15_Installer" > /dev/null
        zypper ar -f "http://192.168.180.1/SLE-15-Packages-x86_64-GM-DVD1/" "SLES_15_Packages" > /dev/null
      else
        zypper ar -f "http://192.168.180.1/SLE-15-${SLES_SERVICEPACK}-Full-x86_64-GM-Media1/" > /dev/null
      fi
    fi
  fi
fi


# this can be very long, we should make it optional

# package that should exist everywhere
${PM_INSTALL} zsh vim less curl binutils rsync
${PM_INSTALL} git || ${PM_INSTALL} git-core
# install that may fail
${PM_INSTALL} htop ldapscripts uuid-runtime tree gnupg 2>/dev/null

# In case the vagrant box is very minimal
if [ "${DEBIAN_VERSION}" = "8" ]
then
  ${PM_INSTALL} dbus
fi

# add common useful files
for user in root vagrant
do
  home=`getent passwd ${user} | cut -d: -f6`
  shopt -s dotglob 2>/dev/null || true
  if [ -d "/tmp/vagrant-cache" ]
  then
    rsync -rl $SCRIPTS_PREFIX/scripts/files/ "${home}"/
  fi
done

# Clean vagrant-cachier cached files for rudder packages
if [ -d "/tmp/vagrant-cache" ]
then
    find /tmp/vagrant-cache -name 'Rudder' -type d | xargs rm -rf
    find /tmp/vagrant-cache -name 'rudder*' -o -name 'ncf*' | xargs rm -f
fi

postclean
exit 0
