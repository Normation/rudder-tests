# use local or typeset to define a local variable
setlocal() {
  local="local"
  $local x=1 2>/dev/null || local="typeset"
}
setlocal

# Reimplement which (taken from 10_ncf_internals/list-compatible-inputs)
which() {
  local name="$1"
  local IFS_SAVE="$IFS"
  IFS=:
  for directory in $PATH
  do
    if [ -x "${directory}/${name}" ]
    then
      echo "${directory}/${name}"
      IFS="$IFS_SAVE"
      return 0
    fi
  done
  IFS="$IFS_SAVE"
  return 1
}

