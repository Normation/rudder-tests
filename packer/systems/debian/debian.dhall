let boot = ./boot_command.dhall
in {
    guest_os_type = "Debian_64",
    os_arch = "amd64",
    os_start = "systems/debian/scripts/os_start.sh",
    os_stop = "systems/debian/scripts/os_stop.sh",
    boot_command = boot.command "ftp.fr.debian.org" "",
    system_dir = "debian"
}

