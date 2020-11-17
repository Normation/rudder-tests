function command(mirror, other)
  return {
    "<enter><wait><f6><esc><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "/install/vmlinuz<wait>",
    " auto<wait>",
    " console-setup/ask_detect=false<wait>",
    " console-keymaps-at/keymap=fr <wait>",
    " console-setup/modelcode=pc105<wait>",
    " debconf/frontend=noninteractive<wait>",
    " debian-installer=en_US.UTF-8<wait>",
    " fb=false<wait>",
    " initrd=/install/initrd.gz<wait>",
    " kbd-chooser/method=fr<wait>",
    " keyboard-configuration/layout=fr<wait>",
    " keyboard-configuration/variant=fr<wait>",
    " locale=en_US<wait>",
    " netcfg/get_domain=vm<wait>",
    " netcfg/get_hostname=vagrant<wait>",
    " grub-installer/bootdev=/dev/sda<wait>",
    " noapic<wait>",
    " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    " -- <wait>",
    "<enter><wait>"
  }
end

guest_os_type = "Ubuntu_64"
os_arch = "amd64"
os_start = "systems/ubuntu/scripts/os_start.sh"
os_stop = "systems/ubuntu/scripts/os_stop.sh"
boot_command = command("","")
system_dir = "ubuntu"
distro = "ubuntu"

