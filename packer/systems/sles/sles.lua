function command(autoinst)
  return {
    "<esc><enter><wait>",
    "linux netdevice=eth0 netsetup=dhcp install=cd:/",
    " lang=en_US autoyast=http://{{ .HTTPIP }}:{{ .HTTPPort }}/" .. autoinst,
    " textmode=1",
    "<enter><wait>",
    "<wait10><wait10><wait10><wait10><wait10><wait10>"
  }
end

guest_os_type = "Sles_64"
os_arch = "amd64"
os_start = "systems/sles/scripts/os_start.sh"
os_stop = "systems/sles/scripts/os_stop.sh"
boot_command = command("")
system_dir = "sles"
distro = "sles"

