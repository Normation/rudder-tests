############################################
# Add rudder repository to package manager #
############################################
add_repo() {

  if [ "${PM}" = "apt" ]
  then
    # Debian / Ubuntu like
    apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 474A19E8
    if [ "${USE_CI}" = "yes" ]
    then
      $local URL_BASE="https://ci.normation.com/apt-repos/release/${RUDDER_VERSION}/"
    else
      $local URL_BASE="http://www.rudder-project.org/apt-${RUDDER_VERSION}/"
    fi
    cat > /etc/apt/sources.list.d/rudder.list << EOF
deb ${URL_BASE} `lsb_release -cs` main
EOF
    apt-get update
    return 0
  
  elif [ "${PM}" = "yum" ]
  then
    # Add RHEL like rpm repo
    $local OSVERSION=`echo "${OS_COMPATIBLE_VERSION}" | sed 's/[^0-9].*//'`
    if [ "${USE_CI}" = "yes" ]
    then
      $local URL_BASE="https://ci.normation.com/rpm-packages/release/${RUDDER_VERSION}/${OS_COMPATIBLE}_${OSVERSION}/"
    else
      $local URL_BASE="http://www.rudder-project.org/rpm-${RUDDER_VERSION}/${OS_COMPATIBLE}_${OSVERSION}/"
    fi
    cat > /etc/yum.repos.d/rudder.repo << EOF
[Rudder_${RUDDER_VERSION}]
name=Rudder ${RUDDER_VERSION} Repository
baseurl=${URL_BASE}
gpgcheck=1
gpgkey=${URL_BASE}repodata/repomd.xml.key
EOF
    rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&fingerprint=on&search=0xADAB3BD36F07D355"
    return 0
  
  elif [ "${PM}" = "zypper" ]
  then
    # Add SuSE repo
    $local OSVERSION=`echo "${OS_COMPATIBLE_VERSION}" | sed 's/[^0-9].*//'`
    if [ "${USE_CI}" = "yes" ]
    then
      $local URL_BASE="https://ci.normation.com/rpm-packages/release/${RUDDER_VERSION}/SLES_${OSVERSION}/"
    else
      $local URL_BASE="http://www.rudder-project.org/rpm-${RUDDER_VERSION}/SLES_${OSVERSION}/"
    fi
    $local OSVERSION=`echo "${OS_COMPATIBLE_VERSION}" | sed 's/[^0-9].*//'`
    rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&fingerprint=on&search=0xADAB3BD36F07D355"
    zypper addrepo -n "Normation RPM Repositories" "${URL_BASE}" Rudder || true
    zypper refresh
    return 0
  fi
  
  # TODO pkgng emerge pacman smartos
  # There is help in Fusion Inventory lib/FusionInventory/Agent/Task/Inventory/Linux/Distro/NonLSB.pm
  echo "Sorry your Package Manager is not *yet* supported !"
  return 1
}

