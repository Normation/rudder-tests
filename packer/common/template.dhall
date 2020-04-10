-- Common template for packer

let Types = ./types.dhall
let Functions = ./functions.dhall

-- Global Vars
let common_scripts =
     [
     "scripts/vagrant.sh"
     ,"scripts/guestAdd.sh"
     ,"scripts/cleanbox.sh"
     ,"scripts/end.sh"
     ]

-- Local Vars
let builders : List Types.Builder =
    -- vbox builder
    let vagrant_sub_builder = Functions.mk_vagrant "vagrant"
    let boot_command = ./boot_command.dhall
    let vbox_builder = Functions.mk_virtualbox_iso boot_command vagrant_sub_builder
    let vbox = Types.Builder.vbox_builder vbox_builder
    in [ vbox ]

let post_processors : List Types.Post_processor =
    -- vagrant box export
    let iso = ./iso.dhall
    let holder = Functions.mk_vagrant_post_processor "builds/${iso.os_name}-${iso.os_arch}.box"
    let vagrant_export = Types.Post_processor.vagrant_post_processor holder
    -- rtf validation
    let holder = Functions.mk_shell_local [ "./test_box.sh /home/fdallidet/Rudder/rudder-api-client /tmp/builds/${iso.os_name}-${iso.os_arch}.box" ]
    let rtf_validation = Types.Post_processor.shell_local holder

    in [ vagrant_export, rtf_validation ]

in {
provisioners =
    [ Functions.run common_scripts
    ]

,builders = builders

,post-processors =
    [
      post_processors
    ]
}
