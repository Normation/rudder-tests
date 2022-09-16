guest_os_type = "RedHat_64"
os_arch = "amd64"
os_start = "systems/centos/scripts/os_start.sh"
os_stop = "systems/centos/scripts/os_stop.sh"
boot_command = "<tab><bs><bs><bs><bs><bs>inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks-9.cfg<enter><wait>"
system_dir = "centos"
distro = "centos"

