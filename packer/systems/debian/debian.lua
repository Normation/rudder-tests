function command(mirror, other) 
  return {
    "<esc><wait>",
    "install <wait>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "mirror/http/hostname=" .. mirror .. " <wait>",
    "debian-installer=en_US.UTF-8 <wait>",
    "auto=true <wait>",
    "kbd-chooser/method=fr <wait>",
    "netcfg/get_hostname={{ .Name }} <wait>",
    "netcfg/get_domain=local <wait>",
    "fb=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=fr <wait>",
    other,
    "<enter><wait>"
  }
end

guest_os_type = "Debian_64"
os_arch = "amd64"
os_start = "systems/debian/scripts/os_start.sh"
os_stop = "systems/debian/scripts/os_stop.sh"
boot_command = command("ftp.fr.debian.org","")
system_dir = "debian"
distro = "debian"

