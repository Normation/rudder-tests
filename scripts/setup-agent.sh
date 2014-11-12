######################
# Setup rudder agent #
######################
setup_agent() {

  # install via package manager only
  if [ -z "${PM}" ]
  then
    echo "Sorry your System is not *yet* supported !"
    exit 4
  fi

  # install
  ${PM_INSTALL} rudder-agent

  # hacks
  #######
  # TODO rhel5 only
  #${PM_INSTALL} pcre openssl db4-devel


  # TODO rudder < 2.11 only
  echo "rudder" > /var/rudder/cfengine-community/policy_server.dat

  /etc/init.d/rudder-agent start
}
