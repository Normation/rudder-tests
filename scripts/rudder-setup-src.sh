#!/bin/sh

set -e

# Documentation !
usage() {
  echo "Usage $0 [add_repository|setup_agent|setup_server] <rudder_version>"
  echo "  Adds a repository and setup rudder on your OS" 
  echo "  Should work on as many OS as possible"
  echo "  Currently suported : Debian, Ubuntu, RHEL, Fedora, Centos, Amazon, Oracle, SLES"
  exit 1
}
# GOTO bottom for main()

# Include: lib.sh

MATRIX=`cat <<'EOF'
# Include: matrix
EOF
`

# Include: detect-os.sh

# Include: add-repo.sh

# Include: setup-agent.sh

# Include: setup-server.sh

########
# MAIN #
########

COMMAND="$1"
RUDDER_VERSION="$2"

detect_os

case "${COMMAND}" in
  add_repository)
    add_repo "${RUDDER_VERSION}"
    ;;
  setup_agent)
    add_repo "${RUDDER_VERSION}"
    setup_agent "${RUDDER_VERSION}"
    ;;
  setup_server)
    add_repo "${RUDDER_VERSION}"
    setup_server "${RUDDER_VERSION}"
    ;;
  *)
    usage
    ;;
esac
