-- Functions
let Types = ./types.dhall

let run = \(x : List Text) -> {
        type = "shell"
        ,execute_command = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
        ,scripts = x
}

let mk_virtualbox_iso =
        \(boot_command : List Text) ->
        \(vagrant : Types.Vagrant_ssh) ->
        let boot_command = boot_command
        let vagrant = vagrant
        let system = ./system.dhall
        let virtualbox_iso : Types.Virtualbox_iso =
        {
            type = "virtualbox-iso"
            ,boot_command = boot_command
            ,boot_wait = "10s"
            ,cpus = "1"
            ,disk_size = "16384"
            ,hard_drive_interface = "sata"
            ,memory = "2048"
            ,shutdown_command = "echo 'vagrant'|sudo -S shutdown -h -P now"
            ,headless = True
            ,http_directory = "systems/${system.system_dir}/http"
            ,guest_additions_path = "VBoxGuestAdditions_{{.Version}}.iso"
            ,virtualbox_version_file = ".vbox_version"
            ,iso_urls = system.iso_urls
            ,iso_checksum_type = "sha256"
            ,iso_checksum = system.iso_checksum
            ,guest_os_type = system.guest_os_type
            ,vm_name = "packer-${system.os_name}-${system.os_arch}"
            ,ssh_username = vagrant.ssh_username
            ,ssh_password = vagrant.ssh_password
            ,ssh_port = vagrant.ssh_port
            ,ssh_timeout = vagrant.ssh_wait_timeout
            ,vboxmanage_post = [["modifymedium", "disk", "--compact", "output-virtualbox-iso/packer-${system.os_name}-${system.os_arch}.vdi"]]
        }
        in virtualbox_iso


let mk_shell_local =
    \(inline : List Text) ->
    let inline = inline
    let shell_local : Types.Shell_local =
    {
      type = "shell-local"
    , inline = inline
    }
    in shell_local

let mk_vagrant_post_processor =
    \(box : Text) ->
    let box = box
    let postproc : Types.Vagrant_post_processor =
    {
      type = "vagrant"
    , output = box
    }
    in postproc

let mk_vagrant =
    \(user : Text) ->
    let user = user
    let vagrant : Types.Vagrant_ssh =
    {
      ssh_username = user
      ,ssh_password = user
      ,ssh_port = "22"
      ,ssh_wait_timeout = "2000s"
    }
    in vagrant

in {run = run
   ,mk_virtualbox_iso = mk_virtualbox_iso
   ,mk_vagrant = mk_vagrant
   ,mk_shell_local = mk_shell_local
   ,mk_vagrant_post_processor = mk_vagrant_post_processor
}
