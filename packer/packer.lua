#!/usr/bin/lua

json = require 'json'
require 'common/strict'

system = arg[1]
publish = arg[2]

-- Load systm specific data
dofile("systems/" .. system .. ".lua")
os_name = distro .. "-" .. os_version
os_full_name = os_name .. "-" .. os_arch

-- exinting box use -64 or -32 instead of amd64 and i386
if os_arch == "amd64" then
  box_name = os_name .. "-64"
elseif os_arch == "i386" then
  box_name = os_name .. "-32"
else 
  box_name = os_full_name
end

-- initialization scripts
local common_scripts = {
    os_start,
    "scripts/start.sh",
    os_script,
    "scripts/vagrant.sh",
    "scripts/guestAdd.sh",
    "scripts/grub.sh",
    os_stop,
    "scripts/stop.sh",
}

-- provision with some files and init scripts
local provisioners_ = {
    {
      destination = "/tmp/",
      source = "files",
      type = "file"
    },
    {
      execute_command = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'",
      scripts = common_scripts,
      type = "shell"
    }
}

-- virtualbox builder
local vbox = {
    type = "virtualbox-iso",
    boot_command = boot_command,
    boot_wait = "10s",
    cpus = "1",
    disk_size = "16384",
    hard_drive_interface = "sata",
    memory = "2048",
    shutdown_command = "echo 'vagrant'|sudo -S shutdown -h -P now",
    headless = true,
    http_directory = "systems/" .. system_dir .. "/http",
    guest_additions_path = "VBoxGuestAdditions_{{.Version}}.iso",
    virtualbox_version_file = ".vbox_version",
    iso_url = iso_url,
    iso_checksum_type = "sha256",
    iso_checksum = iso_checksum,
    guest_os_type = guest_os_type,
    vm_name = "packer-" .. os_full_name,
    ssh_username = "vagrant",
    ssh_password = "vagrant",
    ssh_port = "22",
    ssh_timeout = "2000s",
    vboxmanage_post = {
      { "modifymedium", "disk", "--compact", "output-virtualbox-iso/packer-" .. os_full_name .. ".vdi" }
    }
}


-- vagrant cloud publish
local vagrant_cloud = {
    type = "vagrant-cloud",
    box_tag = "normation/" .. box_name,
    access_token = "{{user `cloud_token`}}",
    version = "2.0"
}

-- Vagrant box creation
local vagrant = {
    type = "vagrant",
    output = "builds/" .. os_full_name .. ".box"
}

-- List of processors
local post_processors_ = { { vagrant, vagrant_cloud } }


-- Generate final json
local conf = {
    provisioners = provisioners_,
    builders = { vbox },
    ["post-processors"] = post_processors_,
}

print ( json.encode( conf ) )
