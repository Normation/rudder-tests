-- Common template for packer
let Types = ./types.dhall
let Functions = ./functions.dhall

let install_agent : List Types.Post_processor =
  -- Download rtf-setup
  let holder = Functions.mk_shell_local [ "curl -L -s -o /usr/local/bin/rudder-setup https://repository.rudder.io/tools/rudder-setup" ]
  let get_rudder_setup = Types.Post_processor.shell_local holder

  -- Install given version
  let holder = Functions.mk_shell_local [ "/usr/local/bin/rudder-setup agent {{user `agent_version`}}" ]
  let install_agent = Types.Post_processor.shell_local holder

  in [ get_rudder_setup, install_agent ]

let tpl = ./template.dhall
let post-processors = { post-processors = tpl.post-processors # [ install_agent ] }
in tpl // post-processors
