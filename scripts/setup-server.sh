#######################
# Setup rudder server #
#######################
setup_server() {
  RUDDER_VERSION="$1"

  # detect package manager
#  apt=`which apt-get`
#  yum=`which yum`
#  zypper=`which zypper`

#  if [ -x "${apt}" ]
#  then
#  elif [ -x "${yum}" ]
#  then
#  elif [ -x "${zypper}" ]
#  then
#  else
    echo "Sorry your System is not supported by Rudder Server !"
    exit 5
#  fi
}

