############################################
# Add rudder repository to package manager #
############################################
add_repo() {
  RUDDER_VERSION="$1"

  if [ "${PM}" = "apt" ]
  then
    # Debian / Ubuntu like
    apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 474A19E8
    cat > /etc/apt/sources.list.d/rudder.list << EOF
deb http://www.rudder-project.org/apt-${RUDDER_VERSION}/ `lsb_release -cs` main
EOF
    apt-get update
    return 0
  
  elif [ "${PM}" = "yum" ]
  then
    # Add RHEL like rpm repo
    OSVERSION=`echo "${OS_COMPATIBLE_VERSION}" | sed 's/[^0-9].*//'`
    cat > /etc/yum.repos.d/rudder.repo << EOF
[Rudder_${RUDDER_VERSION}]
name=Rudder ${RUDDER_VERSION} Repository
baseurl=http://www.rudder-project.org/rpm-${RUDDER_VERSION}/${OS_COMPATIBLE}_${OSVERSION}/
gpgcheck=1
gpgkey=http://www.rudder-project.org/rpm-${RUDDER_VERSION}/${OS_COMPATIBLE}_${OSVERSION}/repodata/repomd.xml.key
EOF
    rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&fingerprint=on&search=0xADAB3BD36F07D355"
    return 0
  
  elif [ "${PM}" = "zypper" ]
  then
    OSVERSION=`echo "${OS_COMPATIBLE_VERSION}" | sed 's/[^0-9].*//'`
    rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&fingerprint=on&search=0xADAB3BD36F07D355"
    zypper addrepo -n "Normation RPM Repositories" "http://www.rudder-project.org/rpm-${RUDDER_VERSION}/SLES_${OSVERSION}/" Rudder || true
    zypper refresh
    return 0
  fi
  
  # TODO pkgng emerge pacman smartos
  # There is help in Fusion Inventory lib/FusionInventory/Agent/Task/Inventory/Linux/Distro/NonLSB.pm
  echo "Sorry your Package Manager is not *yet* supported !"
  return 1
}
