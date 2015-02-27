######################
# Setup rudder agent #
######################
setup_agent() {

  # Install via package manager only
  if [ -z "${PM}" ]
  then
    echo "Sorry your System is not *yet* supported !"
    exit 4
  fi

  # Install
  ${PM_INSTALL} rudder-agent

  # System specific behavior
  #######

  # TODO rhel5 only
  #${PM_INSTALL} pcre openssl db4-devel

  # TODO rudder < 2.11 only
  echo "rudder" > /var/rudder/cfengine-community/policy_server.dat

  service rudder-agent start

}

upgrade_agent() {

  # Upgrade via package manager only
  if [ -z "${PM}" ]
  then
    echo "Sorry your System is not *yet* supported !"
    exit 4
  fi

  # Upgrade
  ${PM_UPGRADE} rudder-agent

}


