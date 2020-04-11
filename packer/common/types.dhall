-- Types
let Vagrant_ssh =
    {
      ssh_username : Text
    , ssh_password : Text
    , ssh_port : Text
    , ssh_wait_timeout : Text
    }

let File_builder =
    {
      type : Text
    , content : Text
    , target : Text
    }

let Shell_local =
    {
      type : Text
    , inline : List Text
    }

let Vagrant_post_processor =
    {
      type : Text
    , output : Text
    }

let Virtualbox_iso =
    {
      type : Text
      ,boot_command : List Text
      ,boot_wait : Text
      ,cpus : Text
      ,disk_size : Text
      ,hard_drive_interface: Text
      ,memory: Text
      ,shutdown_command : Text
      ,headless : Bool
      ,http_directory : Text
      ,guest_additions_path : Text
      ,virtualbox_version_file : Text
      ,iso_urls : List Text
      ,iso_checksum_type : Text
      ,iso_checksum : Text
      ,guest_os_type : Text
      ,vm_name : Text
      ,ssh_username : Text
      ,ssh_password : Text
      ,ssh_port : Text
      ,ssh_timeout : Text
      ,vboxmanage_post : List (List Text)
    }

let Shell_provisioner = 
{
      type : Text
      ,execute_command : Text
      ,scripts : List Text
}

let File_provisioner = 
{
      type : Text,
      source : Text,
      destination : Text
}

let Builder = < file_builder: File_builder | vbox_builder: Virtualbox_iso>
let Post_processor = < vagrant_post_processor: Vagrant_post_processor | shell_local: Shell_local>
let Provisioner = < shell: Shell_provisioner | file: File_provisioner>

in {Vagrant_ssh = Vagrant_ssh
   ,File_builder = File_builder
   ,Virtualbox_iso = Virtualbox_iso
   ,Shell_local = Shell_local
   ,Vagrant_post_processor = Vagrant_post_processor
   ,Builder = Builder
   ,Post_processor = Post_processor
   ,Shell_provisioner = Shell_provisioner
   ,File_provisioner = File_provisioner
   ,Provisioner = Provisioner
}
