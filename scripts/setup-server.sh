#######################
# Setup rudder server #
#######################
setup_server() {

  # install via package manager only
  if [ -z "${PM}" ]
  then
    echo "Sorry your System is not *yet* supported !"
    exit 4
  fi

  # TODO detect supported OS
  # echo "Sorry your System is not supported by Rudder Server !"
  # exit 5

  $local SERVER_HOSTNAME=`hostname`
  $local DEMOSAMPLE="no"
  $local LDAPRESET="yes"
  $local INITPRORESET="yes"
  # TODO detect
  [ -z "${ALLOWEDNETWORK}" ] && $local ALLOWEDNETWORK='127.0.0.1/24'

  # install
  ${PM_INSTALL} rudder-server-root

  # hacks
  #######
  # None at first

  # Initialize Rudder
  /opt/rudder/bin/rudder-init.sh ${SERVER_HOSTNAME} ${DEMOSAMPLE} ${LDAPRESET} ${INITPRORESET} ${ALLOWEDNETWORK} < /dev/null > /dev/null 2>&1
}

