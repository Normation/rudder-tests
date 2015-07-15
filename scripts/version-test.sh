
# matrix file format
# ruddersetup;rudder-version-spec;os;os-version-spec
# ruddersetup = agent / server / multiserver
# os = debian / fedora / ...
# version-spec = 5 / 5.1 / 5.1.5 / 5.1-rc3 / [5 7] / [5.1 7] / [5.1 *] / ... # [A B] means between A and B (A and B included)
# '*' are allowed on all columns
#
# see version_spec() for more details on version specification
# 
# suggested additions : exception(not supported) | hack(script fu) | comment
#| RUDDER_SETUP | RUDDER_VERSION | OS | OS_VERSION | # exception(not supported) | hack(script fu) | comment
#


# A component is a version element, components are separated by '.'
# echo the version component number $id (Nth component)
get_component() {
  $local version="$1"
  $local id="$2"
  echo "${version}" | 
    sed -e 's/[^0-9a-zA-Z ]/ /g' | # use ' ' as a separator
    sed -e 's/\([0-9]\)\([^0-9]\)/\1 \2/g' | # separate after a number (23rc1 -> 23 rc1)
    sed -e 's/\([^0-9]\)\([0-9]\)/\1 \2/g' | # separate before a number (rc2 -> rc 2)
    sed -e 's/  */ /g' | # remove duplicate ' '
    cut -d' ' -f${id} # keep the one we want
}

# Return true if a version component matches a specification component
# Operator can be "-le" "-eq" or "-ge" 
component_cmp() {
  $local version_component="$1"
  $local operator="$2"
  $local spec_component="$3"
  $local alpha_version=`echo -n "${version_component}" | grep "[^0-9]" || true`
  $local alpha_spec=`echo -n "${spec_component}" | grep "[^0-9]" || true`
  if [ -z "${spec_component}" ] # no spec -> match
  then
    return 0
  elif [ -z "${version_component}" ] # no version -> doesn't match
  then
    return 1
  elif [ -z "${alpha_spec}" ] && [ -z "${alpha_version}" ] # both are numeric
  then
    [ "${version_component}" "${operator}" "${spec_component}" ]
  elif [ -z "${alpha_spec}" ] # numeric spec, alpha version -> version is inferior to spec
  then
    [ "${operator}" = "-le" ] # true only for "less than"
  else # alpha spec (beta, rc, ...)
    # hack (alpha < beta < rc) but I see no better way for now
    [ "${operator}" = "-le" ] && op=">"  # Beware !
    [ "${operator}" = "-eq" ] && op="!=" # Beware this is reversed to keep a shell behaviour (0=true)
    [ "${operator}" = "-ge" ] && op="<"  # Beware !
    echo "${version_component} ${spec_component}" | awk "{ exit(\$1 ${op} \$2) }"
  fi
}

# Return true if a version matches a specification
# Operator can be "-le" "-eq" or "-ge"
version_cmp() {
  $local version="$1"
  $local operator="$2"
  $local spec="$3"

  # comparison with * laways matches
  [ "${spec}" = "*" ] && return 0

  # Iterate over components and stop on first component not matching
  for i in 1 2 3 4 5 6 7 8 9 # maximum 9 components
  do
    $local version_component=`get_component "${version}" "${i}"`
    $local spec_component=`get_component "${spec}" "${i}"`

    # if we have a spec component, test against the matching one in version
    if [ -n "${spec_component}" ]
    then
      if component_cmp "${version_component}" "${operator}" "${spec_component}"
      then
        : # continue
      else
        return 1 # stop on error
      fi
    else # given version is more precise than spec -> match
      return 0
    fi

  done
  # given version precisely equals spec or has more than 9 components -> match
  return 0
}

# Return true if the version is compatible with the version specification
# Parameters (version, version specification)
# Version spec is of the form [A B] : between A and B (A and B included)
is_version_valid() {
  $local version_isok="$1"
  $local specification="$2"
  $local v1=`echo "${specification}" | sed 's/[][]//g' | cut -d' ' -f1`
  $local v2=`echo "${specification}" | sed 's/[][]//g' | cut -d' ' -f2`
  if [ -z "${v2}" ]
  then
    version_cmp "${version_isok}" "-eq" "${v1}"
  else
    version_cmp "${version_isok}" "-ge" "${v1}" && version_cmp "${version_isok}" "-le" "${v2}"
  fi
}

# test function for component specification
test_component() {
  $local retval=1
  if [ "$1" = "ok" ]
  then
    retval=0
  fi
  component_cmp "$2" "$3" "$4"
  if [ $? -eq ${retval} ]
  then
    echo "$2 $3 $4 = $1 -> PASS" 
  else
    echo "$2 $3 $4 = $1 -> ERROR" 
  fi
}

# test function for version specification
test_spec() {
  $local retval=1
  if [ "$1" = "ok" ]
  then
    retval=0
  fi
  is_version_valid "$2" "$3"
  if [ $? -eq ${retval} ]
  then
    echo "$2 ~ $3 = $1 -> PASS"
  else
    echo "$2 ~ $3 = $1 -> ERROR"
  fi
}

# This is the test for version comparison
# This test acts as a definition of version specification
version_spec() {
  test_component ok 2 -le 2
  test_component ok 11 -le 12
  test_component ko 12 -le 11
  test_component ok rc -le rc
  test_component ok beta -le rc
  test_component ko beta -le alpha
  test_component ok 2 -eq 2
  test_component ko 11 -eq 12
  test_component ok rc -eq rc
  test_component ko beta -eq rc
  test_component ok 2 -ge 2
  test_component ok 12 -ge 11
  test_component ko 11 -ge 12
  test_component ok rc -ge rc
  test_component ko beta -ge rc
  test_component ok beta -ge alpha


  test_spec ok "2.11" "2.11" 
  test_spec ok "2.11.2" "2.11" 
  test_spec ok "2.11" "[2.11 2.12]"
  test_spec ok "2.12" "[2.11 2.12]" 
  test_spec ok "2.11.2" "[2.11.1 2.11.3]" 
  test_spec ok "2.11-rc1" "2.11"
  test_spec ok "2.11-rc1" "2.11-rc"
  test_spec ok "2.11" "[2.10 *]" 
  test_spec ok "2.11" "[* 2.11]" 
  test_spec ok "2.10-rc1" "[2.10-beta1 2.11]" 
  test_spec ko "2.11" "2.11.2" 
  test_spec ko "2.11-rc1" "2.11.1"
  test_spec ko "2.11" "[2.11.1 2.11.3]" 
  test_spec ko "2.11-rc1" "[2.11.1 2.11.3]" 
  test_spec ko "2.10" "2.11"
  test_spec ko "2.10-rc1" "[2.11.1 2.11.3]" 
  test_spec ko "2.11" "[2.12 *]" 
  test_spec ok "3.1" "[3.0 4.0]" 
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

