
# matrix file format
# ruddersetup;rudder-version-spec;os;os-version-spec
# ruddersetup = agent / server / multiserver
# os = debian / fedora / ...
# version-spec = 5 / 5.1 / 5.1.5 / 5.1-rc3 / 5>7 / 5.1>7 / ... 
# '*' are allow on columns
#
# see version_spec() for details on version specification
# 
# suggested additions : exception(not supported) | hack(script fu) | comment
#| RUDDER_SETUP | RUDDER_VERSION | OS | OS_VERSION | # exception(not supported) | hack(script fu) | comment
#


# echo the version component number $id
get_component() {
  $local version="$1"
  $local id="$2"
  $local component=`echo "${version}" | cut -d. -f${id} | sed -s 's/[^0-9].*//'`
  if [ -z "${component}" ]
  then
    gc_id=`expr ${id} - 1`
    gc_component=`echo "${version}" | cut -d. -f${id} | sed -s 's/[0-9]//g' | sed -s 's/.*[^0-9].*/-1/'`
  fi
  echo "${component}"
}

# return true if the version is between vmin and vmax
version_between() {
  $local version="$1"
  $local vmin="$2"
  $local vmax="$3"
  for i in 1 2 3 4 5 6 7 8 9 # maximum 9 components
  do
    $local version_component=`get_component "${version}" "${i}"`
    $local vmin_component=`get_component "${vmin}" "${i}"`
    $local vmax_component=`get_component "${vmax}" "${i}"`
    if [ -z "${version_component}" ]
    then
      return 0
    fi
    if [ -n "${vmin_component}" ]
    then
      if [ ${version_component} -lt ${vmin_component} ]
      then
        return 1
      fi
    fi
    if [ -n "${vmax_component}" ]
    then
      if [ ${version_component} -gt ${vmax_component} ]
      then
        return 1
      fi
    fi
  done
  return 0
}

# Return true if the version is compatible with the version specification
# Parameters (VERSION, version specification)
is_version_ok() {
  $local VERSION_isok="$1"
  $local version_isok="$2"
  $local v1=`echo "${version_isok}" | sed 's/[][]//g' | cut -d' ' -f1`
  $local v2=`echo "${version_isok}" | sed 's/[][]//g' | cut -d' ' -f2`
  if [ -z "${v2}" ]
  then
    version_between "${VERSION_isok}" "${v1}" "${v1}"
  else
    version_between "${VERSION_isok}" "${v1}" "${v2}"
  fi
}

# test a version specification
test_spec() {
  $local ok="$1"
  $local version="$2"
  $local spec="$3"
  $local retval=1
  if [ "${ok}" = "ok" ]
  then
    retval=0
  fi
  is_version_ok "${version}" "${spec}"
  if [ $? -eq ${retval} ]
  then
    echo "${version}" "${spec}" "-> OK" 
  else
    echo "${version}" "${spec}" "-> ERR" 
  fi
}

# this is the specification for the version comparison
version_spec() {
  test_spec ok "2.11" "2.11" 
  test_spec ok "2.11.2" "2.11" 
  test_spec ok "2.11" "2.11.2" 
  test_spec ok "2.11" "[2.11 2.12]"
  test_spec ok "2.12" "[2.11 2.12]" 
  test_spec ok "2.11" "[2.11.1 2.11.3]" 
  test_spec ok "2.11-rc1" "2.11"
  test_spec ko "2.11-rc1" "2.11.1"
  test_spec ko "2.11-rc1" "[2.11.1 2.11.3]" 
  test_spec ko "2.10" "2.11"
  test_spec ko "2.10" "2.11>2.11.3" 
  test_spec ko "2.10-rc1" "[2.11.1 2.11.3]" 
}


# Return true if parameters are compatible with rudder compatibility matrix
# Parameters (RUDDER, RUDDER_VERSION, OS, OS_VERSION)
# RUDDER : agent / server / multiserver
is_compatible() {
  $local RUDDER="$1"
  $local RUDDER_VERSION="$2"
  $local OS="$3"
  $local OS_VERSION="$3"

  $local EXIT=1

  $local IFS_OLD="$IFS"
  IFS=";$IFS"
  echo "${MATRIX}" | while read rudder rudder_version os os_version
  do
    # check rudderr setup
    if [ "${rudder}" != "*" ] && [ "${rudder}" != "${RUDDER}" ]
    then
      break
    fi
    # check rudder version
    if [ "${rudder_version}" != "*" ]
    then
      if ! is_version_ok "${RUDDER_VERSION}" "${rudder_version}"
      then
        break
      fi
   fi
    # check OS
    if [ "${os}" != "*" ] && [ "${os}" != "${OS}" ]
    then
      break
    fi
    # check OS version
    if [ "${os_version}" != "*" ]
    then
      if ! is_version_ok "${OS_VERSION}" "${os_version}"
      then
        break
      fi
    fi
 
    EXIT=0

  done
  IFS="$IFS_OLD"

  return ${EXIT}
}

